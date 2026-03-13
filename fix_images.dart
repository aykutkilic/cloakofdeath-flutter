import 'dart:io';

void fixFile(String path, bool isMain) {
  var file = File(path);
  var text = file.readAsStringSync();

  // In main.dart, the image is rendered without text next to it. Let's fix that.
  if (isMain) {
    text = text.replaceAll(r'''
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/${item.replaceAll(' ', '_').toLowerCase()}.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Text(
                                                item.length > 3 ? item.substring(0, 3) : item,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 16),
                                              );
                                            },
                                          ),
                                        ),''', r'''
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/${item.replaceAll(' ', '_').toLowerCase()}.png',
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.help_outline, size: 20),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: const TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),''');
    
    // Also change width: 80 to width: 140 to accommodate text
    text = text.replaceAll('width: 80,', 'width: 140,');
  }

  file.writeAsStringSync(text);
}

void main() {
  fixFile('cloak_of_death_flutter/lib/main.dart', true);
}
