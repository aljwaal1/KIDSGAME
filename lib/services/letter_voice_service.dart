import 'sound_service.dart';

class LetterVoiceService {
  const LetterVoiceService._();

  static const List<String> _arabic = <String>[
    'أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي',
  ];

  static Future<bool> playArabic(String letter) {
    final index = _arabic.indexOf(letter);
    if (index < 0) return Future<bool>.value(false);
    final number = (index + 1).toString().padLeft(2, '0');
    return SoundService.instance.playVoiceAsset('letter_ar_$number.wav');
  }

  static Future<bool> playEnglish(String letter) {
    final value = letter.trim().toUpperCase();
    if (value.length != 1 || value.codeUnitAt(0) < 65 || value.codeUnitAt(0) > 90) {
      return Future<bool>.value(false);
    }
    return SoundService.instance.playVoiceAsset('letter_en_$value.wav');
  }
}
