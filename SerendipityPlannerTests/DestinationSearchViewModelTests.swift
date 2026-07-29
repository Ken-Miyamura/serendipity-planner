@testable import SerendipityPlanner
import XCTest

@MainActor
final class DestinationSearchViewModelTests: XCTestCase {
    private var sut: DestinationSearchViewModel!

    override func setUp() {
        super.setUp()
        sut = DestinationSearchViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - IME 変換中の抑止

    /// 「出雲大社」を入力する途中の「出雲大」で候補を取りに行くと、
    /// 六本木の「出雲大社東京分祠」が出てしまう。変換が確定するまで取得しない。
    func testComposingInputDoesNotStartFetch() {
        sut.updateQuery("出雲大", isComposing: true)

        XCTAssertEqual(sut.query, "出雲大", "表示用の文字列は変換中も更新する")
        XCTAssertFalse(sut.isSearching, "変換中は候補取得を開始しない")
        XCTAssertTrue(sut.candidates.isEmpty)
    }

    func testCommittedInputStartsFetch() {
        sut.updateQuery("出雲大社", isComposing: false)

        XCTAssertEqual(sut.query, "出雲大社")
        XCTAssertTrue(sut.isSearching, "確定した入力では候補取得を開始する")
    }

    /// 変換中に取得を止めても、確定した時点で取得が始まること
    func testComposingThenCommitStartsFetch() {
        sut.updateQuery("いずも", isComposing: true)
        XCTAssertFalse(sut.isSearching)

        sut.updateQuery("出雲大社", isComposing: false)
        XCTAssertTrue(sut.isSearching)
    }

    // MARK: - 入力クリア

    func testEmptyQueryClearsCandidates() {
        sut.updateQuery("渋谷", isComposing: false)
        XCTAssertTrue(sut.isSearching)

        sut.updateQuery("", isComposing: false)

        XCTAssertTrue(sut.candidates.isEmpty)
        XCTAssertFalse(sut.isSearching, "クリア時は検索中表示を解除する")
    }

    func testWhitespaceOnlyQueryIsTreatedAsEmpty() {
        sut.updateQuery("   ", isComposing: false)

        XCTAssertTrue(sut.candidates.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - おすすめエリア

    /// 現在地が取れないときは固定データを出さず空にする
    func testRecommendedAreasAreEmptyWithoutLocation() async {
        await sut.loadRecommendedAreas(near: nil)

        XCTAssertTrue(sut.recommendedAreas.isEmpty)
        XCTAssertFalse(sut.isLoadingRecommendations)
    }
}
