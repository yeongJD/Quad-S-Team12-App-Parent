import '../models/whitelist_app.dart';

abstract final class WhitelistAppMockData {
  static const List<WhitelistAppCategory> appleCategories =
      <WhitelistAppCategory>[
        WhitelistAppCategory(
          id: 'all',
          name: '모든 앱 및 카테고리',
          apps: <WhitelistApp>[],
        ),
        WhitelistAppCategory(
          id: 'essentials',
          name: '필수앱',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'phone', name: '전화'),
            WhitelistApp(id: 'messages', name: '문자'),
            WhitelistApp(id: 'contacts', name: '연락처'),
            WhitelistApp(id: 'calendar', name: '캘린더'),
            WhitelistApp(id: 'memo', name: '메모'),
          ],
        ),
        WhitelistAppCategory(
          id: 'social',
          name: '소셜미디어',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'facetime', name: 'FaceTime'),
            WhitelistApp(id: 'kakaotalk', name: '카카오톡'),
            WhitelistApp(id: 'messages', name: '메시지'),
          ],
        ),
        WhitelistAppCategory(
          id: 'games',
          name: '게임',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'game-center', name: 'Game Center'),
            WhitelistApp(id: 'minecraft', name: 'Minecraft'),
            WhitelistApp(id: 'roblox', name: 'Roblox'),
          ],
        ),
        WhitelistAppCategory(
          id: 'entertainment',
          name: '엔터테인먼트',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'youtube', name: 'YouTube'),
            WhitelistApp(id: 'netflix', name: 'Netflix'),
            WhitelistApp(id: 'spotify', name: 'Spotify'),
          ],
        ),
        WhitelistAppCategory(
          id: 'creativity',
          name: '창의력',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'photos', name: '사진'),
            WhitelistApp(id: 'garageband', name: 'GarageBand'),
            WhitelistApp(id: 'clips', name: 'Clips'),
          ],
        ),
        WhitelistAppCategory(
          id: 'productivity-finance',
          name: '생산성 및 금융',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'calendar', name: '캘린더'),
            WhitelistApp(id: 'reminders', name: '미리 알림'),
            WhitelistApp(id: 'wallet', name: '지갑'),
          ],
        ),
        WhitelistAppCategory(
          id: 'education',
          name: '교육',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'classroom', name: 'Classroom'),
            WhitelistApp(id: 'duolingo', name: 'Duolingo'),
            WhitelistApp(id: 'quizlet', name: 'Quizlet'),
          ],
        ),
        WhitelistAppCategory(
          id: 'health-fitness',
          name: '건강 및 피트니스',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'health', name: '건강'),
            WhitelistApp(id: 'fitness', name: '피트니스'),
            WhitelistApp(id: 'nike-run-club', name: 'Nike Run Club'),
          ],
        ),
        WhitelistAppCategory(
          id: 'travel',
          name: '여행',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'maps', name: '지도'),
            WhitelistApp(id: 'translate', name: '번역'),
            WhitelistApp(id: 'find-my', name: '나의 찾기'),
          ],
        ),
        WhitelistAppCategory(
          id: 'other',
          name: '기타',
          apps: <WhitelistApp>[
            WhitelistApp(id: 'settings', name: '설정'),
            WhitelistApp(id: 'contacts', name: '연락처'),
            WhitelistApp(id: 'clock', name: '시계'),
          ],
        ),
      ];
}
