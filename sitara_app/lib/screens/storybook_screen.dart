import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_db_service.dart';
import '../services/tts_service.dart';

class StorybookScreen extends StatefulWidget {
  const StorybookScreen({super.key});

  @override
  State<StorybookScreen> createState() => _StorybookScreenState();
}

class _StorybookScreenState extends State<StorybookScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  late AnimationController _catController;
  late Animation<double> _catAnim;

  late AnimationController _trainController;
  late Animation<double> _trainAnim;

  late AnimationController _jugnuController;
  late Animation<double> _jugnuAnim;

  // Star spin/bounce interactive state
  double _starAngle = 0.0;
  double _starScale = 1.0;
  bool _isStarTapped = false;

  // Coco tap state
  bool _isCatTapped = false;

  // Train tap state
  bool _isTrainTapped = false;

  // Jugnu (firefly) tap state
  bool _isJugnuTapped = false;
  int _jugnuCount = 1;

  // ── Story data: pages are Map<String,String> with 'en' and 'ur' keys ─────────
  static const List<Map<String, dynamic>> _stories = [
    {
      'title': 'The Shiny Little Star',
      'titleUrdu': 'چمکتا چھوٹا ستارہ',
      'emoji': '⭐',
      'accentColor': 0xFFFFD700,
      'pages': [
        {
          'en': 'Look at the beautiful night sky! The sky is deep blue, and a happy little star is twinkling just for you. It is so beautiful!',
          'ur': 'خوبصورت رات کے آسمان کو دیکھو! آسمان گہرا نیلا ہے، اور ایک خوش چھوٹا ستارہ صرف تمہارے لیے چمک رہا ہے!',
        },
        {
          'en': 'The little star moves left and right! Tap the star and it sings a sweet chime — just like a tiny golden bell: Ting! Try it!',
          'ur': 'چھوٹا ستارہ ادھر ادھر ہلتا ہے! ستارے کو تھپتھپاؤ اور یہ ایک پیاری آواز نکالے گا — ایک چھوٹی سنہری گھنٹی کی طرح: ٹنگ!',
        },
        {
          'en': 'Now the big, round moon wakes up with a warm smile. It breathes slowly in and out, gently helping you feel calm and safe.',
          'ur': 'اب بڑا، گول چاند ایک گرم مسکراہٹ کے ساتھ جاگتا ہے۔ یہ آہستہ آہستہ سانس لیتا ہے، تمہیں پُرسکون اور محفوظ محسوس کراتا ہے۔',
        },
        {
          'en': 'Look! Shooting stars zoom across the sky, drawing beautiful glowing lines. They are going so fast! Let us make a quiet wish together.',
          'ur': 'دیکھو! ٹوٹتے ستارے آسمان میں خوبصورت چمکتی لکیریں کھینچتے ہوئے گزرتے ہیں۔ آؤ مل کر ایک خاموش خواہش مانگیں!',
        },
        {
          'en': 'The star whispers a gentle secret: You are so special! You are brave, you are wonderful, and you are so very, very loved!',
          'ur': 'ستارہ آہستہ سے ایک راز بتاتا ہے: تم بہت خاص ہو! تم بہادر ہو، تم شاندار ہو، اور تم سے بہت بہت پیار کیا جاتا ہے!',
        },
        {
          'en': 'High up in the sky, friendly stars are dancing together. They twinkle and sparkle, painting the whole night with light and magic.',
          'ur': 'اونچے آسمان پر، دوستانہ ستارے مل کر ناچ رہے ہیں۔ وہ جھلملاتے اور چمکتے ہیں، پوری رات کو روشنی اور جادو سے بھر دیتے ہیں۔',
        },
        {
          'en': 'The big moon wraps you in soft, silver moonlight. It is like a cozy blanket made of starlight — warm, safe, and full of love.',
          'ur': 'بڑا چاند تمہیں نرم چاندی کی چاندنی میں لپیٹتا ہے۔ یہ تاروں کی روشنی سے بنے آرام دہ کمبل کی طرح ہے — گرم، محفوظ اور محبت سے بھرپور۔',
        },
        {
          'en': 'Your own little star has a name — its name is Sitara! She flies up high to watch over you every single night with love and care.',
          'ur': 'تمہارے اپنے چھوٹے ستارے کا ایک نام ہے — اس کا نام ستارہ ہے! وہ ہر رات تم پر محبت اور پیار سے نظر رکھنے کے لیے اونچا اڑتی ہے۔',
        },
        {
          'en': 'Close your eyes, little explorer. The stars are all around you, keeping you safe and loved. Sweet dreams and quiet, peaceful sleep.',
          'ur': 'آنکھیں بند کرو، چھوٹے مہم جو۔ ستارے تمہارے چاروں طرف ہیں، تمہیں محفوظ اور پیارا رکھتے ہیں۔ اچھے خواب اور پُرسکون نیند!',
        },
      ],
    },
    {
      'title': 'Coco the Kind Cat',
      'titleUrdu': 'کوکو پیاری بلی',
      'emoji': '🐱',
      'accentColor': 0xFFFFB800,
      'pages': [
        {
          'en': 'Coco is a small, fluffy orange kitty! He has tiny velvet paws, long white whiskers, and the warmest, softest fur you have ever felt!',
          'ur': 'کوکو ایک چھوٹی، نرم نارنجی بلی ہے! اس کے چھوٹے مخملی پنجے، لمبی سفید مونچھیں، اور سب سے نرم اور گرم کوٹ ہے!',
        },
        {
          'en': 'Tap Coco to see him jump up high! When you tap his tummy, Coco does a happy little bounce and shouts: Boing! He loves to play!',
          'ur': 'کوکو کو تھپتھپاؤ اور دیکھو وہ اونچا کودتا ہے! جب تم اس کے پیٹ کو چھوتے ہو، کوکو خوشی سے اچھلتا ہے اور کہتا ہے: بوئنگ!',
        },
        {
          'en': 'Coco purrs a happy song: Purr, purr, purr! The sound is warm and cozy, like a soft blanket all around you on a cold, quiet night.',
          'ur': 'کوکو خوشی کا گیت گنگناتا ہے: پرر، پرر، پرر! یہ آواز گرم اور آرام دہ ہے، جیسے ٹھنڈی خاموش رات میں ایک نرم کمبل۔',
        },
        {
          'en': 'He rolls a little red ball of yarn! Roll, roll, roll. Watch it go bouncing across the floor! Coco chases it with his tiny, fast paws.',
          'ur': 'وہ اون کی ایک چھوٹی سرخ گیند لڑھکاتا ہے! لڑھکو، لڑھکو، لڑھکو۔ دیکھو یہ فرش پر اچھلتی جاتی ہے! کوکو اپنے چھوٹے تیز پنجوں سے اس کا پیچھا کرتا ہے۔',
        },
        {
          'en': 'Coco sees a beautiful butterfly! He watches it flutter by — flap, flap, flap — with wide, curious eyes. So many wonderful colours!',
          'ur': 'کوکو ایک خوبصورت تتلی دیکھتا ہے! وہ اسے پھڑپھڑاتے ہوئے دیکھتا ہے — پھڑپھڑ، پھڑپھڑ — چوڑی پیاری آنکھوں سے۔ کتنے خوبصورت رنگ!',
        },
        {
          'en': 'Coco gets a little sleepy after playing so much. He yawns a big yawn — Ahhhhh! — and slowly blinks his shiny, golden eyes at you.',
          'ur': 'بہت کھیلنے کے بعد کوکو تھوڑا نیند محسوس کرتا ہے۔ وہ ایک بڑی جمائی لیتا ہے — آہہہہہ! — اور آہستہ آہستہ اپنی سنہری چمکتی آنکھیں جھپکاتا ہے۔',
        },
        {
          'en': 'Coco walks slowly and gently sits right next to you. He rests his warm, fluffy head against your arm. He loves you very, very much!',
          'ur': 'کوکو آہستہ چلتا ہے اور آہستگی سے تمہارے بالکل پاس بیٹھتا ہے۔ وہ اپنا گرم، نرم سر تمہارے بازو سے لگاتا ہے۔ وہ تم سے بہت بہت پیار کرتا ہے!',
        },
        {
          'en': 'Coco wants to share his favourite snack — a tiny warm bowl of fresh milk! Lap, lap, lap. It is so yummy! Drinking milk makes every day bright!',
          'ur': 'کوکو اپنا پسندیدہ کھانا شیئر کرنا چاہتا ہے — تازہ دودھ کا ایک چھوٹا گرم پیالہ! لپ، لپ، لپ۔ بہت مزیدار! دودھ پینا ہر دن کو روشن بناتا ہے!',
        },
        {
          'en': 'Together you and Coco share a quiet, peaceful, and very happy day. Take a deep breath, smile big, and give your little kitty a gentle hug!',
          'ur': 'مل کر تم اور کوکو ایک پُرسکون، پُرامن، اور بہت خوش دن گزارتے ہو۔ گہری سانس لو، بڑی مسکراہٹ دو، اور اپنی پیاری بلی کو ایک پیارا گلے لگاؤ!',
        },
      ],
    },
    {
      'title': 'The Forest Train Adventure',
      'titleUrdu': 'جنگل کی ریل گاڑی',
      'emoji': '🚂',
      'accentColor': 0xFF43C59E,
      'pages': [
        {
          'en': 'Choo-choo! The happy blue steam train starts its slow, steady journey through the tall, beautiful green forest! What a wonderful adventure!',
          'ur': 'چو-چو! خوش نیلی بھاپ کی ٹرین اونچے، خوبصورت سبز جنگل سے گزرتے ہوئے اپنا آہستہ، مستقل سفر شروع کرتی ہے! کیا شاندار مہم جوئی!',
        },
        {
          'en': 'Chug-chug-chug! Tap the train to hear it blow its soft horn: Toot-toot! The big round wheels spin around and around so smoothly!',
          'ur': 'چگ-چگ-چگ! ٹرین کو تھپتھپاؤ اور سنو یہ اپنا نرم ہارن بجاتی ہے: ٹوٹ-ٹوٹ! بڑے گول پہیے بہت آرام سے گھومتے رہتے ہیں!',
        },
        {
          'en': 'We pass tall green trees that sway gently in the warm wind. Friendly little birds are singing from the branches: Tweet-tweet, tweet!',
          'ur': 'ہم اونچے سبز درختوں سے گزرتے ہیں جو گرم ہوا میں آہستہ سے جھومتے ہیں۔ پیاری چھوٹی چڑیاں شاخوں سے گاتی ہیں: چوئیں-چوئیں، چوئیں!',
        },
        {
          'en': 'Look out the window! We see bright, colourful flowers dancing in the golden sunshine — yellow, red, and bright blue petals all swaying!',
          'ur': 'کھڑکی سے باہر دیکھو! ہم سنہری دھوپ میں ناچتے چمکدار، رنگ برنگے پھول دیکھتے ہیں — پیلی، سرخ اور نیلی پتیاں لہراتی ہیں!',
        },
        {
          'en': 'A little bunny hops alongside the train! Hop, hop, hop! He waves his fluffy white tail at us and then hops away into the cozy forest.',
          'ur': 'ایک چھوٹا خرگوش ٹرین کے ساتھ ساتھ اچھلتا ہے! اچھل، اچھل، اچھل! وہ اپنی نرم سفید دم ہمیں ہلاتا ہے اور پھر آرام دہ جنگل میں غائب ہو جاتا ہے۔',
        },
        {
          'en': 'We sit comfortably inside our safe, warm carriage. The ride is slow, steady, and very relaxing. We feel so happy and cozy inside!',
          'ur': 'ہم اپنے محفوظ، گرم ڈبے میں آرام سے بیٹھتے ہیں۔ سواری آہستہ، مستقل اور بہت آرام دہ ہے۔ ہم بہت خوش اور آرام دہ محسوس کرتے ہیں!',
        },
        {
          'en': 'The train goes through a short, cozy tunnel — it gets dark for a moment, then bright again! Whoosh! We are back in the warm sunshine!',
          'ur': 'ٹرین ایک چھوٹی، آرام دہ سرنگ سے گزرتی ہے — ایک لمحے کے لیے اندھیرا ہوتا ہے، پھر دوبارہ روشن! ووش! ہم دوبارہ گرم دھوپ میں ہیں!',
        },
        {
          'en': 'The forest opens wide and we see a magical waterfall! The water tumbles down with a gentle, rushing sound: Whoosh, whoosh, whoosh!',
          'ur': 'جنگل کھل جاتا ہے اور ہم ایک جادوئی آبشار دیکھتے ہیں! پانی ایک نرم آواز کے ساتھ نیچے گرتا ہے: ووش، ووش، ووش!',
        },
        {
          'en': 'The train safely arrives at the peaceful forest station. All the animals wave goodbye. You did a wonderful job on this adventure! Choo-choo!',
          'ur': 'ٹرین محفوظ طریقے سے پُرامن جنگل کے اسٹیشن پر پہنچتی ہے۔ تمام جانور خدا حافظ کہتے ہیں۔ اس مہم جوئی میں تم نے بہت اچھا کام کیا! چو-چو!',
        },
      ],
    },
    {
      'title': 'Sitara Aur Jugnu',
      'titleUrdu': 'ستارہ اور جگنو',
      'emoji': '🌙',
      'accentColor': 0xFF7C3AED,
      'pages': [
        {
          'en': 'It is a warm, beautiful summer evening in our garden. Ammi is sitting on the charpoy, and Dada Abu is smiling gently from his chair!',
          'ur': 'ہمارے باغ میں ایک گرم، خوبصورت موسمِ گرما کی شام ہے۔ امی چارپائی پر بیٹھی ہیں، اور دادا ابو اپنی کرسی سے آہستہ سے مسکرا رہے ہیں!',
        },
        {
          'en': 'Suddenly, a tiny light flickers in the dark garden — it is a jugnu! A firefly! It glows soft yellow-green, like a tiny dancing star!',
          'ur': 'اچانک، باغ کے اندھیرے میں ایک چھوٹی روشنی چمکتی ہے — یہ ایک جگنو ہے! یہ ایک چھوٹے ناچتے ستارے کی طرح نرم پیلے-سبز رنگ میں چمکتا ہے!',
        },
        {
          'en': 'Tap the jugnu to make it glow! Watch it blink on and off — flash, flash, flash! It is nature\'s own little magic lantern, just for you!',
          'ur': 'جگنو کو تھپتھپاؤ اور اسے چمکاؤ! دیکھو یہ آن اور آف ہوتا ہے — فلیش، فلیش، فلیش! یہ قدرت کی اپنی چھوٹی جادوئی لالٹین ہے، صرف تمہارے لیے!',
        },
        {
          'en': 'Dada Abu says: In my childhood, we used to catch jugnu in a jar. They would light up our room like fairy lights! What a wonderful story!',
          'ur': 'دادا ابو کہتے ہیں: بچپن میں ہم جگنو کو شیشے کے جار میں پکڑتے تھے۔ وہ ہمارے کمرے کو پریوں کی روشنیوں کی طرح روشن کر دیتے تھے! کیا شاندار کہانی!',
        },
        {
          'en': 'Ammi brings a plate of warm, crispy samosas! The smell is so yummy — warm, spicy, and delicious. She smiles and says: Khaao beta! Eat!',
          'ur': 'امی گرم، کرارے سموسوں کی پلیٹ لاتی ہیں! خوشبو بہت لذیذ ہے — گرم، مسالہ دار، اور مزیدار۔ وہ مسکرا کر کہتی ہیں: کھاؤ بیٹا!',
        },
        {
          'en': 'More and more jugnu come flying in the dark! Ten, twenty, thirty little lights! They dance together in the garden like tiny, happy stars!',
          'ur': 'اندھیرے میں اور اور جگنو اڑتے ہوئے آتے ہیں! دس، بیس، تیس چھوٹی روشنیاں! وہ باغ میں چھوٹے خوش ستاروں کی طرح مل کر ناچتے ہیں!',
        },
        {
          'en': 'Dada Abu tells a story about brave little Sitara — a girl who follows a jugnu all the way to a magical garden full of flowers and starlight!',
          'ur': 'دادا ابو بہادر چھوٹی ستارہ کی کہانی سناتے ہیں — ایک لڑکی جو ایک جگنو کی پیروی کرتے ہوئے پھولوں اور روشنی سے بھرے ایک جادوئی باغ تک پہنچتی ہے!',
        },
        {
          'en': 'Ammi gives a warm, soft hug and says: Tum bhi hamari Sitara ho! You are our very own Sitara! You shine bright like a beautiful star, always!',
          'ur': 'امی ایک گرم، نرم گلے لگاتی ہیں اور کہتی ہیں: تم بھی ہماری ستارہ ہو! تم ہمیشہ ایک خوبصورت ستارے کی طرح چمکتے ہو!',
        },
        {
          'en': 'The jugnu blink goodnight — flash, flash, flash. Dada Abu smiles, Ammi hums a soft lullaby. You are safe, you are loved. Goodnight, Sitara!',
          'ur': 'جگنو شب بخیر کہنے کے لیے چمکتے ہیں — فلیش، فلیش، فلیش۔ دادا ابو مسکراتے ہیں، امی ایک نرم لوری گنگناتی ہیں۔ تم محفوظ ہو، تم سے پیار ہے۔ شب بخیر، ستارہ!',
        },
      ],
    },
  ];

  int _selectedStoryIndex = 0;
  int _currentPageIndex = 0;
  bool _isPlayingStory = false;
  bool _isNarrating = false;
  String _narrationLanguage = 'english';

  // Cooldown variables
  bool _cooldownActive = false;
  Duration _cooldownTimeLeft = Duration.zero;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    TtsService().stop(); // Silence everything on arrival

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _catController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _catAnim = Tween<double>(begin: 0.0, end: -35.0).animate(
      CurvedAnimation(parent: _catController, curve: Curves.elasticOut),
    );

    _trainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _trainAnim = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _trainController, curve: Curves.easeInOut),
    );

    _jugnuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _jugnuAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _jugnuController, curve: Curves.easeInOut),
    );

    _checkCooldown();
  }


  void _onStarTapped() {
    TtsService().speakSoundCue('Ting!');
    setState(() {
      _starAngle += 6.28; // full spin
      _starScale = 1.4;
      _isStarTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _starScale = 1.0;
          _isStarTapped = false;
        });
      }
    });
  }

  void _onCatTapped() {
    TtsService().speakSoundCue('Boing!');
    _catController.forward().then((_) => _catController.reverse());
    setState(() {
      _isCatTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCatTapped = false;
        });
      }
    });
  }

  void _onTrainTapped() {
    TtsService().speakSoundCue('Toot-toot!');
    setState(() {
      _isTrainTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isTrainTapped = false;
        });
      }
    });
  }

  void _onJugnuTapped() {
    TtsService().speakSoundCue('Flash!');
    setState(() {
      _isJugnuTapped = true;
      _jugnuCount = (_jugnuCount < 8) ? _jugnuCount + 1 : 1;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isJugnuTapped = false;
        });
      }
    });
  }

  void _checkCooldown() {
    final lastPlay = LocalDbService.instance.getLastStoryPlayTime();
    if (lastPlay != null) {
      final elapsed = DateTime.now().difference(lastPlay);
      const cooldownLimit = Duration(hours: 12);
      if (elapsed < cooldownLimit) {
        setState(() {
          _cooldownActive = true;
          _cooldownTimeLeft = cooldownLimit - elapsed;
        });
        _startCooldownTimer();
        return;
      }
    }
    setState(() {
      _cooldownActive = false;
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final lastPlay = LocalDbService.instance.getLastStoryPlayTime();
      if (lastPlay == null) {
        timer.cancel();
        setState(() => _cooldownActive = false);
        return;
      }
      final elapsed = DateTime.now().difference(lastPlay);
      const cooldownLimit = Duration(hours: 12);
      if (elapsed >= cooldownLimit) {
        timer.cancel();
        setState(() {
          _cooldownActive = false;
          _cooldownTimeLeft = Duration.zero;
        });
      } else {
        setState(() {
          _cooldownTimeLeft = cooldownLimit - elapsed;
        });
      }
    });
  }

  // Triggered when child finishes a story to start the 12-hour limit
  Future<void> _completeStory() async {
    TtsService().stop();
    await LocalDbService.instance.saveLastStoryPlayTime(DateTime.now());
    if (mounted) {
      setState(() {
        _isPlayingStory = false;
        _isNarrating = false;
      });
      _checkCooldown();
    }
  }

  Future<void> _narrateCurrentPage() async {
    if (_isNarrating) return;
    setState(() => _isNarrating = true);

    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<dynamic>;
    final page = pages[_currentPageIndex] as Map<String, dynamic>;

    if (_narrationLanguage == 'urdu') {
      // Always speak the Urdu text when Urdu mode is selected.
      // speakStoryUrdu sets ur-PK profile — Android's South Asian TTS engine
      // can read Urdu script even when ur-PK is not listed as "available".
      final pageText = page['ur'] as String;
      await TtsService().speakStoryUrdu(pageText);
    } else {
      final pageText = page['en'] as String;
      await TtsService().speakStoryEnglish(pageText);
    }

    if (mounted) {
      setState(() => _isNarrating = false);
    }
  }

  void _nextPage() {
    TtsService().stop();
    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<Map<String, String>>;
    if (_currentPageIndex < pages.length - 1) {
      setState(() {
        _currentPageIndex++;
        _isNarrating = false;
      });
      _narrateCurrentPage();
    } else {
      // Completed last page! Activate cooldown limit
      _completeStory();
    }
  }

  void _prevPage() {
    TtsService().stop();
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
        _isNarrating = false;
      });
      _narrateCurrentPage();
    }
  }

  void _startStory(int index) {
    setState(() {
      _selectedStoryIndex = index;
      _currentPageIndex = 0;
      _isPlayingStory = true;
      _isNarrating = false;
      _jugnuCount = 1;
    });
    _narrateCurrentPage();
  }

  // Handy shortcut for evaluation / manual override of 12-hour cooldown
  void _bypassCooldown() {
    TtsService().stop();
    _cooldownTimer?.cancel();
    // Save a timestamp from 13 hours ago to clear cooldown safely
    LocalDbService.instance.saveLastStoryPlayTime(
      DateTime.now().subtract(const Duration(hours: 13)),
    );
    setState(() {
      _cooldownActive = false;
      _isPlayingStory = false;
      _isNarrating = false;
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _breatheController.dispose();
    _catController.dispose();
    _trainController.dispose();
    _jugnuController.dispose();
    _cooldownTimer?.cancel();
    TtsService().stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  // ─── RENDERS ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B26), // Cosmic midnight background
      body: Stack(
        children: [
          // Sensory-calming floating particles / soft glowing background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C0920), Color(0xFF1B1440), Color(0xFF080614)],
                ),
              ),
            ),
          ),

          // Glowing background star animation
          Positioned(
            top: 100,
            right: 40,
            child: RotationTransition(
              turns: _starController,
              child: const Opacity(
                opacity: 0.25,
                child: Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 30,
            child: RotationTransition(
              turns: _starController,
              child: const Opacity(
                opacity: 0.15,
                child: Text('✨', style: TextStyle(fontSize: 36)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                        tooltip: 'Back to Home',
                        onPressed: () {
                          TtsService().stop();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sitara Stories',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Accessible testing key for judges to instantly bypass cooldown
                      GestureDetector(
                        onLongPress: _bypassCooldown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_clock_outlined, size: 14, color: Colors.yellowAccent),
                              SizedBox(width: 4),
                              Text('12h Cap', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _cooldownActive
                      ? _buildCooldownScreen()
                      : (_isPlayingStory ? _buildStoryPlayer() : _buildStorySelector()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Render when a child tries to open a story during the active 12-hour lock
  Widget _buildCooldownScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _breatheAnim,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                  border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.25), width: 3),
                ),
                child: const Center(
                  child: Text('😴⭐', style: TextStyle(fontSize: 76)),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Sitara is Sleeping...',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ستارہ تاروں کے نیچے آرام کر رہی ہے…',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
                fontSize: 16,
                height: 2.0,
                color: const Color(0xFFB8B0FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Next Story Unlocks In:',
                    style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_cooldownTimeLeft),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 32,
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'We protect young eyes! One story every 12 hours.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Explicit parent bypass button in UI for helper convenience
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white38),
              label: const Text('Bypass for Testing (Parents/Judges)', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onPressed: _bypassCooldown,
            ),
          ],
        ),
      ),
    );
  }

  // Render cozy story selection carousel
  Widget _buildStorySelector() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select a Soothing Story',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'کہانی پڑھو — اردو اور انگلش میں',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
              fontSize: 14,
              height: 2.0,
              color: const Color(0xFFB8B0FF),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Bilingual stories with fun animations and calm narration.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _stories.length,
            itemBuilder: (ctx, idx) {
              final story = _stories[idx];
              final color = Color(story['accentColor'] as int);
              final pageCount = (story['pages'] as List).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => _startStory(idx),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(story['emoji'] as String, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  story['titleUrdu'] as String,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
                                    fontSize: 13,
                                    height: 1.8,
                                    color: color.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.menu_book_rounded, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$pageCount Pages of Joy',
                                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Render the interactive, high-quality storybook player
  Widget _buildStoryPlayer() {
    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<Map<String, String>>;
    final page = pages[_currentPageIndex];
    final color = Color(story['accentColor'] as int);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (idx) => Container(
                width: 28,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: idx <= _currentPageIndex ? color : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Narrator Voice Toggle Segment
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageSegmentButton('english', 'English (Male)', color),
                _buildLanguageSegmentButton('urdu', 'اردو (Female)', color),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Illustration card
          Expanded(
            flex: 4,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: _buildInteractiveIllustration(color),
            ),
          ),

          const SizedBox(height: 16),

          // Bilingual narrative prose block
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // English narrative
                    Text(
                      page['en']!,
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        height: 1.55,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Urdu subtitle
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        page['ur']!,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
                          fontSize: 15,
                          height: 2.0,
                          color: color.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Interactive controls: Back / Speak / Next
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.navigate_before_rounded, size: 36),
                onPressed: _currentPageIndex > 0 ? _prevPage : null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              // Narrator audio repeat button
              Semantics(
                label: 'Repeat narration',
                button: true,
                child: InkWell(
                  onTap: _narrateCurrentPage,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      _isNarrating ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                icon: Icon(
                  _currentPageIndex < pages.length - 1 ? Icons.navigate_next_rounded : Icons.check_circle_rounded,
                  size: 36,
                ),
                onPressed: _nextPage,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: color.withValues(alpha: 0.2),
                  foregroundColor: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildLanguageSegmentButton(String lang, String label, Color color) {
    final isSelected = _narrationLanguage == lang;
    return GestureDetector(
      onTap: () {
        TtsService().stop();
        setState(() {
          _narrationLanguage = lang;
          _isNarrating = false;
        });
        _narrateCurrentPage();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveIllustration(Color color) {
    switch (_selectedStoryIndex) {
      case 0:
        return _buildSpaceEnvironment(color);
      case 1:
        return _buildCocoPlayground(color);
      case 2:
        return _buildForestTrainScene(color);
      case 3:
        return _buildGardenScene(color);
      default:
        return Center(
          child: Text(
            _stories[_selectedStoryIndex]['emoji'] as String,
            style: const TextStyle(fontSize: 100),
          ),
        );
    }
  }

  Widget _buildSpaceEnvironment(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF020617)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 30, right: 40, child: Text('✨', style: TextStyle(fontSize: 20))),
          const Positioned(bottom: 50, left: 30, child: Text('✨', style: TextStyle(fontSize: 18))),
          const Positioned(top: 100, left: 60, child: Text('✨', style: TextStyle(fontSize: 16))),
          const Positioned(bottom: 80, right: 60, child: Text('✨', style: TextStyle(fontSize: 22))),

          // Floating breathing moon
          Positioned(
            top: 24,
            left: 24,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: const Text('🌙', style: TextStyle(fontSize: 48)),
            ),
          ),

          // Glowing hint/ting bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isStarTapped ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _isStarTapped ? '✨ Ting! ✨' : 'Tap the star!',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isStarTapped ? const Color(0xFFFFD700) : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Central interactive twinkling Star
          Center(
            child: GestureDetector(
              onTap: _onStarTapped,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _starScale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedRotation(
                  turns: _starAngle / 6.28,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: _isStarTapped ? 15 : 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      '⭐',
                      style: TextStyle(fontSize: 110),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCocoPlayground(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA), Color(0xFFFFEDD5)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          const Positioned(top: 20, right: 30, child: Text('☁️', style: TextStyle(fontSize: 32))),
          const Positioned(top: 40, left: 40, child: Text('☁️', style: TextStyle(fontSize: 24))),

          // Interactive Yarn Ball
          Positioned(
            bottom: 40,
            right: 40,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: const Text('🧶', style: TextStyle(fontSize: 48)),
            ),
          ),

          // Dialogue/Reaction Bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isCatTapped ? '😺 Purr! Boing!' : 'Tap Coco the cat!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ),
          ),

          // Central interactive bouncing Cat
          Center(
            child: AnimatedBuilder(
              animation: _catController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _catAnim.value),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _onCatTapped,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: _isCatTapped ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      '🐱',
                      style: TextStyle(fontSize: 100),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestTrainScene(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECFDF5), Color(0xFFA7F3D0), Color(0xFF34D399)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          const Positioned(bottom: 80, left: 30, child: Text('🌲', style: TextStyle(fontSize: 48))),
          const Positioned(bottom: 90, right: 30, child: Text('🌲', style: TextStyle(fontSize: 54))),
          const Positioned(bottom: 100, left: 100, child: Text('🌳', style: TextStyle(fontSize: 40))),

          // Action bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isTrainTapped ? '🚂 Toot-toot! Choo-choo!' : 'Tap the steam train!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ),
          ),

          // Steam puff when tapped
          if (_isTrainTapped)
            Positioned(
              top: 80,
              left: 120,
              child: ScaleTransition(
                scale: _breatheAnim,
                child: const Text('💨', style: TextStyle(fontSize: 36)),
              ),
            ),

          // Central interactive chugging Train
          Center(
            child: AnimatedBuilder(
              animation: _trainController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_trainAnim.value, 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _onTrainTapped,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: _isTrainTapped ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Text(
                    '🚂',
                    style: TextStyle(fontSize: 110),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pakistani garden scene — Sitara Aur Jugnu
  Widget _buildGardenScene(Color color) {
    // Build a grid of jugnu (fireflies) based on _jugnuCount
    final jugnuEmojis = List.generate(_jugnuCount, (i) => i);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1A2E1A), Color(0xFF0B1F0B)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Stack(
        children: [
          // Garden greenery at bottom
          const Positioned(bottom: 10, left: 10, child: Text('🌿', style: TextStyle(fontSize: 36))),
          const Positioned(bottom: 10, right: 10, child: Text('🌿', style: TextStyle(fontSize: 36))),
          const Positioned(bottom: 14, left: 55, child: Text('🌸', style: TextStyle(fontSize: 28))),
          const Positioned(bottom: 14, right: 55, child: Text('🌸', style: TextStyle(fontSize: 28))),

          // Stars in the sky
          const Positioned(top: 24, left: 30, child: Text('✨', style: TextStyle(fontSize: 16))),
          const Positioned(top: 18, right: 50, child: Text('✨', style: TextStyle(fontSize: 14))),
          const Positioned(top: 40, left: 100, child: Text('✨', style: TextStyle(fontSize: 12))),

          // Family members — Ammi and Dada Abu
          const Positioned(bottom: 55, left: 16, child: Text('👩', style: TextStyle(fontSize: 36))),
          const Positioned(bottom: 55, right: 16, child: Text('👴', style: TextStyle(fontSize: 36))),

          // Floating extra jugnu when tapped
          if (_jugnuCount > 1)
            ...jugnuEmojis.skip(1).take(7).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final positions = [
                const Offset(60, 30), const Offset(140, 50), const Offset(200, 25),
                const Offset(90, 80), const Offset(170, 70), const Offset(40, 60),
                const Offset(230, 45),
              ];
              final pos = positions[i % positions.length];
              return Positioned(
                top: pos.dy,
                left: pos.dx,
                child: AnimatedBuilder(
                  animation: _jugnuAnim,
                  builder: (ctx, _) => Opacity(
                    opacity: _jugnuAnim.value,
                    child: const Text('✨', style: TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),

          // Action bubble
          Positioned(
            top: 18,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _isJugnuTapped
                      ? '✨ Flash! جگنو چمکا! ✨'
                      : 'Tap the jugnu — جگنو کو چھوؤ!',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isJugnuTapped ? const Color(0xFFD4FF00) : Colors.white70,
                  ),
                ),
              ),
            ),
          ),

          // Central interactive jugnu (firefly)
          Center(
            child: GestureDetector(
              onTap: _onJugnuTapped,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _jugnuAnim,
                builder: (ctx, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4FF00).withValues(
                            alpha: _isJugnuTapped ? 0.7 : _jugnuAnim.value * 0.5,
                          ),
                          blurRadius: _isJugnuTapped ? 60 : 30,
                          spreadRadius: _isJugnuTapped ? 20 : 8,
                        ),
                      ],
                    ),
                    child: AnimatedScale(
                      scale: _isJugnuTapped ? 1.35 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Opacity(
                        opacity: _jugnuAnim.value,
                        child: const Text('🌟', style: TextStyle(fontSize: 96)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Moon in corner
          Positioned(
            top: 22,
            right: 22,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: const Text('🌙', style: TextStyle(fontSize: 38)),
            ),
          ),
        ],
      ),
    );
  }
}
