import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/driver_info.dart';
import '../../data/models/driver_location.dart';
import '../../data/models/ride.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/active_ride_state.dart';
import '../providers/ride_providers.dart';
import '../providers/ride_booking_provider.dart';

// ── Active Ride Provider ──────────────────────────────────

final activeRideProvider =
    StateNotifierProvider<ActiveRideNotifier, ActiveRideState>((ref) {
  return ActiveRideNotifier(ref);
});

class ActiveRideNotifier extends StateNotifier<ActiveRideState> {
  final Ref _ref;
  Timer? _mockLocationTimer;
  Timer? _mockStatusTimer;
  Timer? _pollingTimer;

  /// Prevents duplicate socket listener setup across multiple calls.
  bool _socketListenersAttached = false;

  /// Prevents re-entrant calls to initFromSocketEvent for the same ride.
  bool _isInitializing = false;

  ActiveRideNotifier(this._ref) : super(const ActiveRideState());

  /// Initialize with a ride ID after driver is found.
  Future<void> initializeRide(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (AppConstants.kDevBypass) {
        await Future.delayed(const Duration(milliseconds: 500));

        final mockRide = Ride(
          id: rideId,
          status: 'DRIVER_EN_ROUTE',
          pickupAddress: AppConstants.isTestMode ? 'Hitech City, Hyderabad' : '14 Republic Street, Valletta',
          pickupLat: AppConstants.defaultLat,
          pickupLng: AppConstants.defaultLng,
          dropoffAddress: AppConstants.isTestMode ? 'Rajiv Gandhi Intl Airport' : 'Malta International Airport',
          dropoffLat: AppConstants.defaultLat - 0.04,
          dropoffLng: AppConstants.defaultLng - 0.04,
          vehicleType: 'STANDARD',
          paymentMethod: 'CASH',
          estimatedFare: 19.80,
          createdAt: DateTime.now().toIso8601String(),
        );

        final mockDriver = const DriverInfo(
          id: 'driver-001',
          name: 'Marco Borg',
          phone: '+35679001234',
          rating: 4.8,
          totalRides: 1247,
          vehicleMake: 'Toyota',
          vehicleModel: 'Camry',
          vehicleColor: 'White',
          plateNumber: 'GZL 042',
          vehicleType: 'Standard',
          memberSince: 'January 2024',
        );

        final mockLocation = DriverLocation(
          latitude: AppConstants.defaultLat + 0.005,
          longitude: AppConstants.defaultLng + 0.005,
          heading: 180,
          speed: 30,
        );

        state = ActiveRideState(
          ride: mockRide,
          driverInfo: mockDriver,
          driverLocation: mockLocation,
          status: ActiveRideStatus.driverEnRoute,
          etaMinutes: 4,
          otpPin: '4829',
          isLoading: false,
          baseFare: 8.50,
          distanceFare: 4.50,
          timeFare: 2.00,
          bookingFee: 1.50,
          surgeMultiplier: 1.2,
        );

        _startMockLocationUpdates();
        _startMockStatusProgression();
        return;
      }

      // Real implementation: fetch ride + driver info from API
      final ds = _ref.read(rideRemoteDatasourceProvider);
      final ride = await ds.getActiveRide();
      if (ride != null) {
        state = state.copyWith(
          ride: ride,
          status: _mapApiStatus(ride.status),
          isLoading: false,
        );
        _listenToSocketUpdates();
        _startStatusPolling();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load ride details.',
      );
    }
  }

  void updateDriverLocation(DriverLocation location) {
    state = state.copyWith(driverLocation: location);
  }

  void updateStatus(ActiveRideStatus newStatus) {
    state = state.copyWith(status: newStatus);
  }

  void updateEta(int minutes) {
    state = state.copyWith(etaMinutes: minutes);
  }

  void setOtpPin(String pin) {
    state = state.copyWith(otpPin: pin);
  }

  /// Initialize active ride from a socket 'ride:accepted' event.
  /// Fetches full ride details via direct API call.
  Future<void> initFromSocketEvent(Map<String, dynamic> data) async {
    final rideId = data['rideId'] as String? ?? '';
    if (kDebugMode) print('[ActiveRide] initFromSocketEvent called, rideId=$rideId');
    if (kDebugMode) print('[ActiveRide] socket event data keys: ${data.keys.toList()}');
    if (rideId.isEmpty) {
      if (kDebugMode) print('[ActiveRide] ABORT — rideId is empty');
      return;
    }

    // ── Guard: skip if already initialized for this ride or currently initializing ──
    if (_isInitializing) {
      if (kDebugMode) print('[ActiveRide] SKIP — already initializing');
      return;
    }
    if (state.ride?.id == rideId && !state.isLoading && state.ride?.pickupAddress?.isNotEmpty == true) {
      if (kDebugMode) print('[ActiveRide] SKIP — already initialized for ride $rideId');
      // Ensure socket listeners are attached (idempotent)
      if (!_socketListenersAttached) _listenToSocketUpdates();
      return;
    }

    _isInitializing = true;
    state = state.copyWith(isLoading: true);

    try {
      final dio = _ref.read(dioProvider);

      // Fetch the FULL ride details as raw JSON
      if (kDebugMode) print('[ActiveRide] GET /rides/$rideId ...');
      final response = await dio.get('/rides/$rideId');
      final json = response.data as Map<String, dynamic>;
      if (kDebugMode) print('[ActiveRide] API response keys: ${json.keys.toList()}');
      if (kDebugMode) print('[ActiveRide] API status: ${json['status']}');

      // 1. Parse the Ride object
      final ride = Ride.fromJson(json);
      if (kDebugMode) print('[ActiveRide] Ride parsed: id=${ride.id}, pickup=${ride.pickupAddress}, dropoff=${ride.dropoffAddress}');

      // 2. Parse driver info from nested object
      DriverInfo? driverInfo;
      final d = json['driver'] as Map<String, dynamic>?;
      if (kDebugMode) print('[ActiveRide] driver json: ${d != null ? d.keys.toList() : 'NULL'}');
      if (d != null) {
        final va = d['vehicleAssignment'] as Map<String, dynamic>?;
        final v = va?['vehicle'] as Map<String, dynamic>? ?? {};
        final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
        if (kDebugMode) print('[ActiveRide] driver name=$name, phone=${d['phone']}, vehicle=$v');
        driverInfo = DriverInfo(
          id: d['driverId'] as String? ?? d['id'] as String? ?? '',
          name: name.isNotEmpty ? name : 'Driver',
          phone: d['phone'] as String? ?? '',
          rating: _safeDouble(d['avgRating'], 5.0),
          totalRides: _safeInt(d['totalRides'], 0),
          vehicleMake: v['make'] as String? ?? '',
          vehicleModel: v['model'] as String? ?? '',
          vehicleColor: v['color'] as String? ?? '',
          plateNumber: v['plateNumber'] as String? ?? '',
          vehicleType: v['type'] as String? ?? ride.vehicleType,
        );
      }

      // 3. Parse driver location
      DriverLocation? driverLocation;
      final dl = json['driverLocation'] as Map<String, dynamic>?;
      if (kDebugMode) print('[ActiveRide] driverLocation json: $dl');
      if (dl != null) {
        final lat = _safeDouble(dl['lat'], 0);
        final lng = _safeDouble(dl['lng'], 0);
        if (lat != 0 || lng != 0) {
          driverLocation = DriverLocation(latitude: lat, longitude: lng);
          if (kDebugMode) print('[ActiveRide] driverLocation parsed: $lat, $lng');
        }
      }

      // 4. Parse OTP
      final otp = json['otp'] as String? ?? data['otp'] as String? ?? '';
      if (kDebugMode) print('[ActiveRide] OTP: $otp');

      // 5. Calculate initial ETA
      int eta = 5;
      if (driverLocation != null) {
        final dist = _haversineKm(
          driverLocation.latitude, driverLocation.longitude,
          ride.pickupLat, ride.pickupLng,
        );
        eta = (dist / 30 * 60).round().clamp(1, 120);
        if (kDebugMode) print('[ActiveRide] ETA calculated: ${dist.toStringAsFixed(2)} km → $eta min');
      }

      // 6. Map status
      final status = _mapApiStatus(json['status'] as String? ?? 'DRIVER_EN_ROUTE');
      if (kDebugMode) print('[ActiveRide] Mapped status: $status');

      state = ActiveRideState(
        ride: ride,
        driverInfo: driverInfo,
        driverLocation: driverLocation,
        status: status,
        etaMinutes: eta,
        otpPin: otp.isNotEmpty ? otp : null,
        isLoading: false,
      );
      if (kDebugMode) print('[ActiveRide] State set successfully ✓');

      // Attach socket listeners and start polling only once per ride session
      if (!_socketListenersAttached) _listenToSocketUpdates();
      if (_pollingTimer == null || !_pollingTimer!.isActive) _startStatusPolling();
    } catch (e, st) {
      if (kDebugMode) print('[ActiveRide] initFromSocketEvent FAILED: $e');
      if (kDebugMode) print('[ActiveRide] Stack trace: $st');
      // Only set minimal state if we don't already have a valid ride loaded
      if (state.ride?.id != rideId || state.ride?.pickupAddress?.isEmpty != false) {
        state = ActiveRideState(
          ride: Ride(
            id: rideId,
            status: 'ACCEPTED',
            pickupAddress: '',
            pickupLat: 0,
            pickupLng: 0,
            dropoffAddress: '',
            dropoffLat: 0,
            dropoffLng: 0,
            vehicleType: '',
            paymentMethod: '',
            createdAt: DateTime.now().toIso8601String(),
          ),
          status: ActiveRideStatus.driverEnRoute,
          etaMinutes: 5,
          otpPin: data['otp'] as String?,
          isLoading: false,
        );
      } else {
        // Already have valid state — just clear loading
        state = state.copyWith(isLoading: false);
      }
      // Do NOT call _listenToSocketUpdates on failure if already attached
      if (!_socketListenersAttached) _listenToSocketUpdates();
    } finally {
      _isInitializing = false;
    }
  }

  StreamSubscription? _socketLocationSub;
  StreamSubscription? _socketStatusSub;
  StreamSubscription? _socketCompletedSub;
  StreamSubscription? _socketChatSub;
  StreamSubscription? _socketDestChangeSub;

  void _listenToSocketUpdates() {
    if (_socketListenersAttached) {
      if (kDebugMode) print('[ActiveRide] Socket listeners already attached — skipping');
      return;
    }
    _socketListenersAttached = true;

    final socketService = _ref.read(socketServiceProvider);
    final rideId = state.ride?.id;

    // Ensure socket is connected and user is in the ride room
    if (!socketService.isConnected) {
      if (kDebugMode) print('[ActiveRide] Socket not connected — connecting now');
      socketService.connect();
    }
    if (rideId != null && rideId.isNotEmpty) {
      if (kDebugMode) print('[ActiveRide] Joining ride room: $rideId');
      socketService.joinRide(rideId);
    }

    _socketLocationSub?.cancel();
    _socketLocationSub = socketService.onDriverLocation.listen((data) {
      if (!mounted) return;
      final lat = (data['lat'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (data['lng'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble() ?? 0;
      if (kDebugMode) print('[ActiveRide] Driver location from socket: lat=$lat, lng=$lng');
      if (lat == 0 && lng == 0) return; // Skip invalid zero coordinates
      final newHeading = (data['heading'] as num?)?.toDouble() ?? 0;
      final newSpeed = (data['speed'] as num?)?.toDouble() ?? 0;
      
      state = state.copyWith(
        driverLocation: DriverLocation(
          latitude: lat,
          longitude: lng,
          heading: (newHeading == 0 && state.driverLocation != null) 
              ? state.driverLocation!.heading : newHeading,
          speed: newSpeed,
        ),
      );


      // Recalculate ETA from socket driver location
      if (state.ride != null) {
        final tLat = state.status == ActiveRideStatus.inProgress
            ? state.ride!.dropoffLat : state.ride!.pickupLat;
        final tLng = state.status == ActiveRideStatus.inProgress
            ? state.ride!.dropoffLng : state.ride!.pickupLng;
        final dist = _haversineKm(lat, lng, tLat, tLng);
        final eta = (dist / 30 * 60).round().clamp(1, 120);
        state = state.copyWith(etaMinutes: eta);
      }
    });

    _socketStatusSub?.cancel();
    _socketStatusSub = socketService.onRideStatusUpdate.listen((data) {
      if (!mounted) return;
      final status = data['status'] as String? ?? '';
      if (kDebugMode) print('[Socket] onRideStatusUpdate: status=$status, data keys=${data.keys.toList()}');
      switch (status) {
        case 'DRIVER_ARRIVED':
          if (kDebugMode) print('[Socket] → DRIVER_ARRIVED');
          final otp = data['otp'] as String?;
          state = state.copyWith(
            status: ActiveRideStatus.driverArrived,
            etaMinutes: 0,
            otpPin: (otp != null && otp.isNotEmpty) ? otp : state.otpPin,
          );
          break;
        case 'IN_PROGRESS':
          if (kDebugMode) print('[Socket] → IN_PROGRESS');
          state = state.copyWith(status: ActiveRideStatus.inProgress);
          break;
        case 'COMPLETED':
          if (kDebugMode) print('[Socket] → COMPLETED');
          completeRide(actualFare: _safeDouble(data['actualFare'], 0));
          break;
        case 'CANCELLED':
          final cancelledBy = data['cancelledBy'] as String? ?? '';
          if (kDebugMode) print('[Socket] → CANCELLED (by: $cancelledBy)');
          final reason = cancelledBy == 'DRIVER'
              ? 'Your driver cancelled the ride.'
              : cancelledBy == 'USER'
                  ? 'You cancelled the ride.'
                  : 'Your ride has been cancelled.';
          state = state.copyWith(
            status: ActiveRideStatus.cancelled,
            cancelReason: reason,
          );
          break;
      }
    });

    _socketCompletedSub?.cancel();
    _socketCompletedSub = socketService.onRideCompleted.listen((data) {
      if (!mounted) return;
      final actualFare = _safeDouble(data['actualFare'], 0);
      completeRide(actualFare: actualFare);
    });

    // Listen for incoming chat messages from driver
    _socketChatSub?.cancel();
    _socketChatSub = socketService.onChatMessage.listen((data) {
      if (!mounted) return;
      final senderRole = data['senderRole'] as String? ?? '';
      if (senderRole == 'USER') return; // Ignore own messages
      final rideId = state.ride?.id ?? '';
      if (rideId.isEmpty) return;
      _ref.read(chatMessagesProvider(rideId).notifier).addIncomingMessage(
        ChatMessage(
          id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          rideId: rideId,
          senderId: data['senderId'] as String? ?? '',
          senderRole: senderRole.isNotEmpty ? senderRole : 'DRIVER',
          message: data['message'] as String? ?? data['content'] as String? ?? '',
          timestamp: data['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int).toIso8601String()
              : data['timestamp'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    });

    // Listen for destination change responses from driver
    _socketDestChangeSub?.cancel();
    _socketDestChangeSub = socketService.onDestinationChangeResponse.listen((data) {
      if (!mounted) return;
      final accepted = data['accepted'] == true;
      if (kDebugMode) print('[ActiveRide] Destination change ${accepted ? 'ACCEPTED' : 'REJECTED'} by driver');
      if (accepted && state.pendingNewDropoffAddress != null) {
        // Update ride with ALL pending destination fields
        state = state.copyWith(
          ride: state.ride?.copyWith(
            dropoffAddress: state.pendingNewDropoffAddress,
            dropoffLat: state.pendingNewDropoffLat ?? state.ride!.dropoffLat,
            dropoffLng: state.pendingNewDropoffLng ?? state.ride!.dropoffLng,
            estimatedFare: state.pendingNewFare ?? state.ride!.estimatedFare,
          ),
          clearPendingDestination: true,
          clearError: true,
        );
        if (kDebugMode) print('[ActiveRide] Ride updated: dropoff=${state.ride?.dropoffAddress}, '
            'lat=${state.ride?.dropoffLat}, lng=${state.ride?.dropoffLng}, fare=${state.ride?.estimatedFare}');
      } else {
        // Driver rejected — show message to user
        state = state.copyWith(
          clearPendingDestination: true,
          errorMessage: 'Driver declined the destination change request.',
        );
      }
    });
  }

  void _cancelSocketSubs() {
    _socketListenersAttached = false;
    _socketLocationSub?.cancel();
    _socketStatusSub?.cancel();
    _socketCompletedSub?.cancel();
    _socketChatSub?.cancel();
    _socketDestChangeSub?.cancel();
  }

  Future<void> cancelRide(String reason) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (state.ride != null) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        await ds.cancelRide(state.ride!.id, reason);
      }
    } catch (_) {
      // Cancel locally even if API fails
    }

    _stopMockTimers();
    state = state.copyWith(
      status: ActiveRideStatus.cancelled,
      cancelReason: reason,
      isLoading: false,
    );

    // Add ride cancellation notification
    try {
      _ref.read(notificationsProvider.notifier).addLocalNotification(
        type: 'RIDE_UPDATE',
        title: 'Ride Cancelled',
        body: 'Your ride to ${state.ride?.dropoffAddress ?? 'your destination'} has been cancelled. You can book a new ride anytime.',
        data: {
          'subtype': 'ride_cancelled',
          'rideId': state.ride?.id ?? '',
        },
      );
    } catch (_) {}
  }

  Future<String?> shareRide() async {
    if (state.ride == null) return null;

    // Return cached URL if already generated
    if (state.shareTrackingUrl != null) return state.shareTrackingUrl;

    if (kDebugMode) print('[ActiveRide] shareRide called for ride=${state.ride!.id}');

    // Always build a fallback URL so copy/share works even if API is down
    final fallbackUrl = 'https://gozolt.com/track/${state.ride!.id}';

    if (AppConstants.kDevBypass) {
      state = state.copyWith(shareTrackingUrl: fallbackUrl);
      return fallbackUrl;
    }
    try {
      final ds = _ref.read(rideRemoteDatasourceProvider);
      final response = await ds.shareRide(state.ride!.id);
      if (kDebugMode) print('[ActiveRide] shareRide response: $response');
      final url = response['trackingUrl'] as String? ?? fallbackUrl;
      state = state.copyWith(shareTrackingUrl: url);
      return url;
    } catch (e) {
      if (kDebugMode) print('[ActiveRide] Share API failed ($e) — using fallback URL');
      // Use fallback so the user can still share a link
      state = state.copyWith(shareTrackingUrl: fallbackUrl);
      return fallbackUrl;
    }
  }

  Future<void> triggerSos(double lat, double lng) async {
    if (state.ride == null) return;

    try {
      if (!AppConstants.kDevBypass) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        await ds.triggerSos(state.ride!.id, lat, lng);
      }
    } catch (_) {
      // SOS should still allow calling 112 even if API fails
    }
  }

  Future<void> rateRide(int rating, {String? comment}) async {
    if (state.ride == null) return;

    try {
      if (!AppConstants.kDevBypass) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        await ds.rateRide(state.ride!.id, rating, comment: comment);
      }
    } catch (_) {
      // Rating failure is non-blocking
    }
  }

  /// Send a tip to the driver after ride completion.
  Future<void> sendTip(double amount) async {
    if (state.ride == null) return;
    try {
      if (!AppConstants.kDevBypass) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        // TODO: Replace with real API call
        await ds.addTip(state.ride!.id, amount);
      }
      // Dev bypass: just simulate success
    } catch (_) {
      // Tip failure is non-blocking
    }
  }

  /// Request a destination change mid-ride.
  Future<void> requestDestinationChange({
    required String newAddress,
    required double newLat,
    required double newLng,
  }) async {
    state = state.copyWith(isDestinationChangePending: true);

    if (AppConstants.kDevBypass) {
      final currentFare = state.ride?.estimatedFare ?? 19.80;
      final newFare = currentFare + 4.70;

      state = state.copyWith(
        pendingNewDropoffAddress: newAddress,
        pendingNewFare: newFare,
      );

      // Simulate driver response after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted && state.isDestinationChangePending) {
          // Mock: 80% accept, 20% reject
          final accepted = DateTime.now().second % 5 != 0;
          if (accepted) {
            state = state.copyWith(
              ride: state.ride != null
                  ? Ride(
                      id: state.ride!.id,
                      status: state.ride!.status,
                      pickupAddress: state.ride!.pickupAddress,
                      pickupLat: state.ride!.pickupLat,
                      pickupLng: state.ride!.pickupLng,
                      dropoffAddress: newAddress,
                      dropoffLat: newLat,
                      dropoffLng: newLng,
                      vehicleType: state.ride!.vehicleType,
                      paymentMethod: state.ride!.paymentMethod,
                      estimatedFare: newFare,
                      actualFare: state.ride!.actualFare,
                      createdAt: state.ride!.createdAt,
                    )
                  : null,
              clearPendingDestination: true,
            );
          } else {
            state = state.copyWith(clearPendingDestination: true);
          }
        }
      });
      return;
    }

    // Production: POST /rides/:id/change-destination
    // This creates a PENDING request — driver must accept/reject.
    // The actual destination update happens when the driver accepts via socket.
    try {
      final ds = _ref.read(rideRemoteDatasourceProvider);
      final response = await ds.changeDestination(
        state.ride!.id,
        newDropoffLat: newLat,
        newDropoffLng: newLng,
        newDropoffAddress: newAddress,
      );
      if (kDebugMode) print('[ActiveRide] changeDestination request created: $response');

      final updatedFare = _safeDouble(
        response['newEstimatedFare'] ?? response['estimatedFare'],
        state.ride!.estimatedFare ?? 0,
      );
      // Store pending details — don't update ride yet, wait for driver response
      state = state.copyWith(
        isDestinationChangePending: true,
        pendingNewDropoffAddress: newAddress,
        pendingNewDropoffLat: newLat,
        pendingNewDropoffLng: newLng,
        pendingNewFare: updatedFare,
      );
    } catch (e) {
      if (kDebugMode) print('[ActiveRide] changeDestination error: $e');
      state = state.copyWith(clearPendingDestination: true);
    }
  }

  /// Cancel a pending destination change request.
  Future<void> cancelDestinationChange() async {
    if (!state.isDestinationChangePending || state.ride == null) return;

    try {
      if (!AppConstants.kDevBypass) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        await ds.cancelDestinationChange(state.ride!.id);
      }
    } catch (e) {
      if (kDebugMode) print('[ActiveRide] cancelDestinationChange error: $e');
    }

    state = state.copyWith(clearPendingDestination: true);
  }

  void completeRide({double? actualFare}) {
    if (kDebugMode) print('[ActiveRide] completeRide called, actualFare=$actualFare');
    _pollingTimer?.cancel();
    _cancelSocketSubs();
    _stopMockTimers();
    state = state.copyWith(
      status: ActiveRideStatus.completed,
      ride: actualFare != null && actualFare > 0 && state.ride != null
          ? state.ride!.copyWith(actualFare: actualFare)
          : state.ride,
    );

    // Add ride completion notification with ride details
    try {
      final ride = state.ride;
      final fare = actualFare ?? ride?.actualFare ?? ride?.estimatedFare;
      final fareStr = fare != null ? '€${fare.toStringAsFixed(2)}' : '';
      final pickup = ride?.pickupAddress ?? '';
      final dropoff = ride?.dropoffAddress ?? '';
      final distance = ride?.distanceKm;
      final distStr = distance != null ? '${distance.toStringAsFixed(1)} km' : '';

      final body = 'Ride completed! ${fareStr.isNotEmpty ? fareStr : ''}'
          '${pickup.isNotEmpty && dropoff.isNotEmpty ? ' — $pickup → $dropoff' : ''}'
          '${distStr.isNotEmpty ? ' ($distStr)' : ''}. Tap for details.';

      _ref.read(notificationsProvider.notifier).addLocalNotification(
        type: 'RIDE_UPDATE',
        title: 'Thank you for riding with us!',
        body: body,
        data: {
          'subtype': 'ride_completed',
          'rideId': ride?.id ?? '',
        },
      );
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> checkoutRide() async {
    if (state.ride == null) return;
    state = state.copyWith(isPaymentLoading: true, clearError: true);

    try {
      final rideId = state.ride!.id;
      // Get selected payment method from booking state (if available) or ride object
      final bookingState = _ref.read(rideBookingProvider);
      final method = bookingState.paymentMethodType.name.toUpperCase();
      final methodId = bookingState.paymentMethodType == PaymentMethodType.card 
          ? bookingState.selectedCardId : null;

      if (AppConstants.kDevBypass) {
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(isPaymentLoading: false, isPaid: true);
        return;
      }

      final ds = _ref.read(paymentRemoteDatasourceProvider);
      await ds.checkoutRide(
        rideId: rideId,
        paymentMethod: method,
        paymentMethodId: methodId,
      );

      state = state.copyWith(isPaymentLoading: false, isPaid: true);
    } catch (e) {
      state = state.copyWith(
        isPaymentLoading: false,
        errorMessage: 'Payment failed. Please try again.',
      );
    }
  }

  /// Check for an active ride on app startup / resume.
  /// Calls GET /rides/active and restores full ride state if one exists.
  Future<void> checkForActiveRide() async {
    // Skip if we already have an active ride loaded
    if (state.ride != null && !state.isCompleted && !state.isCancelled) return;

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/rides/active');
      final json = response.data as Map<String, dynamic>;
      final apiStatus = json['status'] as String? ?? '';

      // Skip completed/cancelled
      if (apiStatus == 'COMPLETED' || apiStatus == 'CANCELLED') return;

      if (kDebugMode) print('[ActiveRide] checkForActiveRide: found ride ${json['id']}, status=$apiStatus');

      // Parse ride
      final ride = Ride.fromJson(json);

      // Parse driver info
      DriverInfo? driverInfo;
      final d = json['driver'] as Map<String, dynamic>?;
      if (d != null) {
        final va = d['vehicleAssignment'] as Map<String, dynamic>?;
        final v = va?['vehicle'] as Map<String, dynamic>? ?? {};
        final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
        driverInfo = DriverInfo(
          id: d['driverId'] as String? ?? d['id'] as String? ?? '',
          name: name.isNotEmpty ? name : 'Driver',
          phone: d['phone'] as String? ?? '',
          rating: _safeDouble(d['avgRating'], 5.0),
          totalRides: _safeInt(d['totalRides'], 0),
          vehicleMake: v['make'] as String? ?? '',
          vehicleModel: v['model'] as String? ?? '',
          vehicleColor: v['color'] as String? ?? '',
          plateNumber: v['plateNumber'] as String? ?? '',
          vehicleType: v['type'] as String? ?? ride.vehicleType,
        );
      }

      // Parse driver location
      DriverLocation? driverLocation;
      final dl = json['driverLocation'] as Map<String, dynamic>?;
      if (dl != null) {
        final lat = _safeDouble(dl['lat'], 0);
        final lng = _safeDouble(dl['lng'], 0);
        if (lat != 0 || lng != 0) {
          driverLocation = DriverLocation(latitude: lat, longitude: lng);
        }
      }

      // Parse OTP
      final otp = json['otp'] as String? ?? '';

      // Calculate ETA
      int eta = 5;
      if (driverLocation != null) {
        final tLat = apiStatus == 'IN_PROGRESS' ? ride.dropoffLat : ride.pickupLat;
        final tLng = apiStatus == 'IN_PROGRESS' ? ride.dropoffLng : ride.pickupLng;
        final dist = _haversineKm(
          driverLocation.latitude, driverLocation.longitude, tLat, tLng,
        );
        eta = (dist / 30 * 60).round().clamp(1, 120);
      }

      final status = _mapApiStatus(apiStatus);

      state = ActiveRideState(
        ride: ride,
        driverInfo: driverInfo,
        driverLocation: driverLocation,
        status: status,
        etaMinutes: eta,
        otpPin: otp.isNotEmpty ? otp : null,
        isLoading: false,
      );

      if (kDebugMode) print('[ActiveRide] Restored active ride: ${ride.id}, status=$status');

      // Only attach socket listeners and start polling if not already running
      if (!_socketListenersAttached) _listenToSocketUpdates();
      if (_pollingTimer == null || !_pollingTimer!.isActive) _startStatusPolling();
    } on DioException catch (e) {
      // 404 = no active ride, that's normal
      if (e.response?.statusCode == 404) return;
      if (kDebugMode) print('[ActiveRide] checkForActiveRide error: $e');
    } catch (e) {
      if (kDebugMode) print('[ActiveRide] checkForActiveRide error: $e');
    }
  }

  void reset() {
    _stopMockTimers();
    _cancelSocketSubs();
    _isInitializing = false;
    state = const ActiveRideState();
  }

  void _startStatusPolling() {
    _pollingTimer?.cancel();
    // Poll every 30 seconds — socket events handle real-time updates
    // Polling only acts as a fallback for status sync
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (!mounted || state.ride == null) return;

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/rides/active');
      if (!mounted) return;

      final json = response.data as Map<String, dynamic>;
      final apiStatus = json['status'] as String? ?? '';
      final newStatus = _mapApiStatus(apiStatus);
      if (kDebugMode) print('[Poll] apiStatus=$apiStatus → $newStatus (current=${state.status})');

      // --- Status change ---
      if (newStatus != state.status) {
        // For scheduled rides: only allow transitions AWAY from scheduled
        // (e.g., when a driver is actually assigned). Never downgrade back to driverEnRoute.
        final isScheduledDowngrade = state.status == ActiveRideStatus.scheduled &&
            newStatus == ActiveRideStatus.driverEnRoute &&
            apiStatus != 'ACCEPTED' && apiStatus != 'DRIVER_EN_ROUTE';

        if (!isScheduledDowngrade) {
          if (kDebugMode) print('[Poll] STATUS CHANGED: ${state.status} → $newStatus');

          if (newStatus == ActiveRideStatus.completed) {
            completeRide(actualFare: _safeDouble(json['actualFare'], 0));
            return;
          }
          state = state.copyWith(status: newStatus);
        } else {
          if (kDebugMode) print('[Poll] Ignoring driverEnRoute override of scheduled status (apiStatus=$apiStatus)');
        }
      }

      // --- OTP ---
      final otp = json['otp'] as String?;
      if (otp != null && otp.isNotEmpty && state.otpPin != otp) {
        if (kDebugMode) print('[Poll] OTP updated: $otp');
        state = state.copyWith(otpPin: otp);
      }

      // --- Driver location ---
      final dl = json['driverLocation'] as Map<String, dynamic>?;
      if (dl != null) {
        final lat = _safeDouble(dl['lat'], 0);
        final lng = _safeDouble(dl['lng'], 0);
        if (lat != 0 || lng != 0) {
          if (kDebugMode) print('[Poll] driverLocation: $lat, $lng');
          state = state.copyWith(
            driverLocation: DriverLocation(latitude: lat, longitude: lng),
          );

          // --- ETA ---
          if (state.ride != null) {
            final tLat = newStatus == ActiveRideStatus.inProgress
                ? state.ride!.dropoffLat : state.ride!.pickupLat;
            final tLng = newStatus == ActiveRideStatus.inProgress
                ? state.ride!.dropoffLng : state.ride!.pickupLng;
            final dist = _haversineKm(lat, lng, tLat, tLng);
            final eta = (dist / 30 * 60).round().clamp(1, 120);
            state = state.copyWith(etaMinutes: eta);
          }
        }
      }

      // --- Driver info (update if missing or placeholder) ---
      final needsDriver = state.driverInfo == null ||
          state.driverInfo!.name == 'Driver' ||
          state.driverInfo!.name.isEmpty ||
          state.driverInfo!.phone.isEmpty;
      if (needsDriver) {
        final d = json['driver'] as Map<String, dynamic>?;
        if (d != null) {
          final va = d['vehicleAssignment'] as Map<String, dynamic>?;
          final v = va?['vehicle'] as Map<String, dynamic>? ?? {};
          final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
          if (kDebugMode) print('[Poll] Updating driver info: name=$name, phone=${d['phone']}');
          state = state.copyWith(
            driverInfo: DriverInfo(
              id: d['driverId'] as String? ?? d['id'] as String? ?? '',
              name: name.isNotEmpty ? name : 'Driver',
              phone: d['phone'] as String? ?? '',
              rating: _safeDouble(d['avgRating'], 5.0),
              vehicleMake: v['make'] as String? ?? '',
              vehicleModel: v['model'] as String? ?? '',
              vehicleColor: v['color'] as String? ?? '',
              plateNumber: v['plateNumber'] as String? ?? '',
              vehicleType: v['type'] as String? ?? '',
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[Poll] Error: $e');
    }
  }

  /// Safely parse a value that may be num or String to double.
  static double _safeDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _safeInt(dynamic v, int fallback) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  ActiveRideStatus _mapApiStatus(String apiStatus) {
    switch (apiStatus) {
      case 'SCHEDULED':
        return ActiveRideStatus.scheduled;
      case 'ACCEPTED':
      case 'DRIVER_EN_ROUTE':
        return ActiveRideStatus.driverEnRoute;
      case 'DRIVER_ARRIVED':
        return ActiveRideStatus.driverArrived;
      case 'IN_PROGRESS':
        return ActiveRideStatus.inProgress;
      case 'COMPLETED':
        return ActiveRideStatus.completed;
      case 'CANCELLED':
        return ActiveRideStatus.cancelled;
      default:
        // Preserve current status for unknown states rather than defaulting to driverEnRoute
        return state.status;
    }
  }

  // ── Mock helpers for dev ────────────────────────────────

  void _startMockLocationUpdates() {
    _mockLocationTimer?.cancel();
    double lat = AppConstants.defaultLat + 0.005;
    double lng = AppConstants.defaultLng + 0.005;
    _mockLocationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      lat -= 0.0003;
      lng += 0.0001;
      if (mounted) {
        state = state.copyWith(
          driverLocation: DriverLocation(
            latitude: lat,
            longitude: lng,
            heading: 180,
            speed: 35,
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
      }
    });
  }

  void _startMockStatusProgression() {
    _mockStatusTimer?.cancel();
    // After 8s → DRIVER_ARRIVED
    _mockStatusTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        state = state.copyWith(
          status: ActiveRideStatus.driverArrived,
          etaMinutes: 0,
        );

        // After another 10s → IN_PROGRESS
        _mockStatusTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            state = state.copyWith(
              status: ActiveRideStatus.inProgress,
              etaMinutes: 18,
            );

            // After 15s of in-progress → COMPLETED
            _mockStatusTimer = Timer(const Duration(seconds: 15), () {
              if (mounted) {
                completeRide(actualFare: 19.80);
              }
            });
          }
        });
      }
    });
  }

  void _stopMockTimers() {
    _mockLocationTimer?.cancel();
    _mockStatusTimer?.cancel();
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _stopMockTimers();
    _cancelSocketSubs();
    super.dispose();
  }
}

// ── Chat Messages Provider ────────────────────────────────

final chatMessagesProvider =
    StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
        (ref, rideId) {
  return ChatNotifier(ref, rideId);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  final String rideId;

  ChatNotifier(this._ref, this.rideId) : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final ds = _ref.read(rideRemoteDatasourceProvider);
      final response = await ds.getRideMessages(rideId);
      final messages = response
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      state = messages;
    } catch (_) {
      // Keep empty state on error
    }
  }

  Future<void> sendMessage(String content) async {
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tempId,
      rideId: rideId,
      senderId: 'current-user',
      senderRole: 'USER',
      message: content,
      timestamp: DateTime.now().toIso8601String(),
      isSending: true,
    );

    state = [...state, message];

    try {
      // Send via WebSocket — the backend gateway persists and broadcasts
      final socket = _ref.read(socketServiceProvider);
      socket.sendChatMessage(rideId, content);

      state = [
        for (final m in state)
          if (m.id == tempId) m.copyWith(isSending: false) else m,
      ];
    } catch (_) {
      state = [
        for (final m in state)
          if (m.id == tempId)
            m.copyWith(isSending: false, hasFailed: true)
          else
            m,
      ];
    }
  }

  void addIncomingMessage(ChatMessage message) {
    state = [...state, message];
  }
}
