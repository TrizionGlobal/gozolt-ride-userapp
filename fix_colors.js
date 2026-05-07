const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else if (file.endsWith('.dart')) {
            results.push(file);
        }
    });
    return results;
}

const files = walk('./lib');
files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let changed = false;

    // Fix withValues -> withOpacity
    if (content.includes('withValues(alpha:')) {
        content = content.replace(/withValues\(alpha: ([^)]+)\)/g, 'withOpacity($1)');
        changed = true;
    }

    // Fix duplicate underscores in lambdas
    if (content.includes('(_, _)')) {
        content = content.replace(/\(_, _\)/g, '(context, error)');
        changed = true;
    }
    if (content.includes('(_, _, _)')) {
        content = content.replace(/\(_, _, _\)/g, '(context, error, stackTrace)');
        changed = true;
    }

    // Fix activeThumbColor
    if (content.includes('activeThumbColor:')) {
        content = content.replace(/activeThumbColor: [^,]+,/g, '');
        changed = true;
    }

    // Fix DialogThemeData -> DialogTheme
    if (content.includes('DialogThemeData')) {
        content = content.replace(/DialogThemeData/g, 'DialogTheme');
        changed = true;
    }

    // Fix CardThemeData -> CardTheme
    if (content.includes('CardThemeData')) {
        content = content.replace(/CardThemeData/g, 'CardTheme');
        changed = true;
    }

    if (changed) {
        console.log(`Fixing: ${file}`);
        fs.writeFileSync(file, content);
    }
});
console.log('All fixes applied!');
