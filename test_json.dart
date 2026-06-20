import 'dart:convert';

void main() {
  final bookData = <String, dynamic>{};
  final json = {
    'lessons': bookData['lessons'] ?? [],
  };
  try {
    final list = (json['lessons'] as List<dynamic>).cast<String>();
    print('Success: $list');
  } catch (e, stack) {
    print('Error: $e');
  }
}
