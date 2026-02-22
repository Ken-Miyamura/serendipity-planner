import Foundation

enum SuggestionTemplates {
    struct Template {
        let category: SuggestionCategory
        let title: String
        let description: String
        let minDuration: Int
    }

    private static let templatesByCategory: [SuggestionCategory: [Template]] = [
        .cafe: [
            Template(
                category: .cafe,
                title: "近くのカフェでひと息",
                description: "温かい飲み物を片手に、ゆったりとした時間を過ごしましょう。新しいカフェを開拓するのも良いですね。",
                minDuration: 30
            ),
            Template(
                category: .cafe,
                title: "カフェで作業タイム",
                description: "お気に入りのカフェで集中作業。環境を変えると新しいアイデアが浮かぶかもしれません。",
                minDuration: 60
            ),
            Template(
                category: .cafe,
                title: "カフェでスイーツタイム",
                description: "頑張った自分へのご褒美に、美味しいスイーツとコーヒーはいかがですか？",
                minDuration: 30
            )
        ],
        .walk: [
            Template(
                category: .walk,
                title: "近所をお散歩",
                description: "気分転換に外を歩きましょう。いつもと違う道を通ると、新しい発見があるかもしれません。",
                minDuration: 20
            ),
            Template(
                category: .walk,
                title: "公園でリフレッシュ",
                description: "近くの公園まで散歩して、自然の中でリフレッシュ。深呼吸で心もスッキリ。",
                minDuration: 30
            ),
            Template(
                category: .walk,
                title: "フォトウォーク",
                description: "カメラやスマホを片手に街歩き。何気ない日常の中に、素敵な瞬間を見つけましょう。",
                minDuration: 45
            )
        ],
        .reading: [
            Template(
                category: .reading,
                title: "読書タイム",
                description: "積読本を消化するチャンス！静かな場所で本の世界に没頭しましょう。",
                minDuration: 30
            ),
            Template(
                category: .reading,
                title: "雑誌・記事を読む",
                description: "気になっていた記事や雑誌を読む時間に。新しい知識やインスピレーションを得ましょう。",
                minDuration: 20
            ),
            Template(
                category: .reading,
                title: "図書館でゆっくり",
                description: "図書館で静かな読書タイム。新しいジャンルの本との出会いを楽しんで。",
                minDuration: 60
            )
        ],
        .music: [
            Template(
                category: .music,
                title: "音楽カフェでリラックス",
                description: "お気に入りの音楽を聴きながら、カフェでゆったり過ごしましょう。",
                minDuration: 30
            ),
            Template(
                category: .music,
                title: "レコードショップ巡り",
                description: "レコードショップで新しい音楽を発掘。思わぬ名盤に出会えるかも。",
                minDuration: 45
            ),
            Template(
                category: .music,
                title: "ライブを楽しむ",
                description: "近くのライブハウスやイベントで、生の音楽を体感しましょう。",
                minDuration: 60
            )
        ],
        .art: [
            Template(
                category: .art,
                title: "ギャラリーを巡る",
                description: "近くのギャラリーでアート鑑賞。新しい視点やインスピレーションが見つかるかも。",
                minDuration: 30
            ),
            Template(
                category: .art,
                title: "美術館でアート体験",
                description: "美術館でじっくりアートに浸りましょう。心が豊かになる時間です。",
                minDuration: 60
            ),
            Template(
                category: .art,
                title: "アートスポット散策",
                description: "街中のパブリックアートやストリートアートを探してみませんか。",
                minDuration: 45
            )
        ],
        .fitness: [
            Template(
                category: .fitness,
                title: "ジョギングでリフレッシュ",
                description: "軽いジョギングで体と心をリフレッシュ。気持ちのいい汗を流しましょう。",
                minDuration: 20
            ),
            Template(
                category: .fitness,
                title: "ジムでトレーニング",
                description: "近くのジムで体を動かしましょう。運動後の爽快感は格別です。",
                minDuration: 45
            ),
            Template(
                category: .fitness,
                title: "ヨガでリラックス",
                description: "ヨガで心身のバランスを整えましょう。呼吸に集中して、心を落ち着けて。",
                minDuration: 30
            )
        ],
        .shopping: [
            Template(
                category: .shopping,
                title: "雑貨屋さん巡り",
                description: "可愛い雑貨を探しにお出かけ。お気に入りのアイテムが見つかるかも。",
                minDuration: 30
            ),
            Template(
                category: .shopping,
                title: "ウィンドウショッピング",
                description: "気ままにショッピングを楽しみましょう。トレンドチェックにもぴったり。",
                minDuration: 45
            ),
            Template(
                category: .shopping,
                title: "セレクトショップ探索",
                description: "こだわりのセレクトショップで、新しいお気に入りを見つけましょう。",
                minDuration: 30
            )
        ],
        .gourmet: [
            Template(
                category: .gourmet,
                title: "新しいお店を開拓",
                description: "気になっていたお店に行ってみましょう。新しい味との出会いが待っています。",
                minDuration: 45
            ),
            Template(
                category: .gourmet,
                title: "食べ歩きを楽しむ",
                description: "街を歩きながら、美味しいものを食べ歩き。小さな幸せを見つけましょう。",
                minDuration: 30
            ),
            Template(
                category: .gourmet,
                title: "ランチで気分転換",
                description: "いつもと違うお店でランチタイム。美味しいご飯で午後も頑張れます。",
                minDuration: 45
            )
        ],
        .movie: [
            Template(
                category: .movie,
                title: "映画館で最新作を",
                description: "話題の映画を観に行きましょう。大画面と音響で、没入感のある体験を。",
                minDuration: 90
            ),
            Template(
                category: .movie,
                title: "ミニシアターで名作を",
                description: "ミニシアターで隠れた名作に出会いましょう。新しい映画体験が待っています。",
                minDuration: 90
            )
        ],
        .meditation: [
            Template(
                category: .meditation,
                title: "お寺で静かなひととき",
                description: "お寺や神社で心を静めましょう。日常から離れて、穏やかな時間を。",
                minDuration: 30
            ),
            Template(
                category: .meditation,
                title: "スパでリラックス",
                description: "スパや銭湯で体をほぐしましょう。心身ともにリフレッシュできます。",
                minDuration: 60
            ),
            Template(
                category: .meditation,
                title: "瞑想タイム",
                description: "静かな場所で瞑想の時間を。呼吸に集中して、心をクリアにしましょう。",
                minDuration: 20
            )
        ]
    ]

    static var allTemplates: [Template] {
        templatesByCategory.values.flatMap(\.self)
    }

    static func templates(for category: SuggestionCategory) -> [Template] {
        templatesByCategory[category] ?? []
    }
}
