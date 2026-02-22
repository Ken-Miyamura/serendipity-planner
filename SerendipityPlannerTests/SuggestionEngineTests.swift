import XCTest
@testable import SerendipityPlanner

final class SuggestionEngineTests: XCTestCase {
    var engine: SuggestionEngine!

    override func setUp() {
        super.setUp()
        engine = SuggestionEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Weather Adjustment Tests

    func testWeatherAdjustment_rainyDay_reducesWalkWeight() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .walk, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .cafe, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0),
        ]

        let rainyWeather = WeatherData(
            temperature: 15.0,
            condition: .rain,
            description: "雨",
            humidity: 80,
            windSpeed: 5.0,
            fetchedAt: Date()
        )

        let adjusted = engine.applyWeatherAdjustment(weights: weights, weather: rainyWeather)

        let walkWeight = adjusted.first(where: { $0.category == .walk })!.weight
        let cafeWeight = adjusted.first(where: { $0.category == .cafe })!.weight

        XCTAssertLessThan(walkWeight, 1.0, "Walk weight should decrease on rainy days")
        XCTAssertGreaterThan(cafeWeight, 1.0, "Cafe weight should increase on rainy days")
    }

    func testWeatherAdjustment_clearDay_increasesWalkWeight() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .walk, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .cafe, weight: 1.0),
        ]

        let clearWeather = WeatherData(
            temperature: 20.0,
            condition: .clear,
            description: "晴れ",
            humidity: 40,
            windSpeed: 2.0,
            fetchedAt: Date()
        )

        let adjusted = engine.applyWeatherAdjustment(weights: weights, weather: clearWeather)

        let walkWeight = adjusted.first(where: { $0.category == .walk })!.weight

        // Clear + comfortable temperature: 1.0 * 1.5 * 1.3 = 1.95
        XCTAssertGreaterThan(walkWeight, 1.5, "Walk weight should increase significantly on clear, comfortable days")
    }

    func testWeatherAdjustment_coldDay_increasesCafeWeight() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .cafe, weight: 1.0),
        ]

        let coldWeather = WeatherData(
            temperature: 5.0,
            condition: .clear,
            description: "晴れ",
            humidity: 30,
            windSpeed: 2.0,
            fetchedAt: Date()
        )

        let adjusted = engine.applyWeatherAdjustment(weights: weights, weather: coldWeather)

        let cafeWeight = adjusted.first(where: { $0.category == .cafe })!.weight
        XCTAssertGreaterThan(cafeWeight, 1.0, "Cafe weight should increase on cold days")
    }

    func testWeatherAdjustment_newCategories_indoorBoostedOnRain() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .movie, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .fitness, weight: 1.0),
        ]

        let rainyWeather = WeatherData(
            temperature: 8.0,
            condition: .rain,
            description: "雨",
            humidity: 80,
            windSpeed: 5.0,
            fetchedAt: Date()
        )

        let adjusted = engine.applyWeatherAdjustment(weights: weights, weather: rainyWeather)

        let movieWeight = adjusted.first(where: { $0.category == .movie })!.weight
        let fitnessWeight = adjusted.first(where: { $0.category == .fitness })!.weight

        XCTAssertGreaterThan(movieWeight, 1.0, "Movie weight should increase on rainy days")
        XCTAssertLessThan(fitnessWeight, 1.0, "Fitness weight should decrease on cold rainy days")
    }

    // MARK: - Time Adjustment Tests

    func testTimeAdjustment_morning_favorsCafe() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .cafe, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .walk, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0),
        ]

        let adjusted = engine.applyTimeAdjustment(weights: weights, hour: 10)

        let cafeWeight = adjusted.first(where: { $0.category == .cafe })!.weight
        XCTAssertGreaterThan(cafeWeight, 1.0, "Cafe weight should increase in morning hours")
    }

    func testTimeAdjustment_evening_favorsReading() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .cafe, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .walk, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0),
        ]

        let adjusted = engine.applyTimeAdjustment(weights: weights, hour: 20)

        let readingWeight = adjusted.first(where: { $0.category == .reading })!.weight
        let walkWeight = adjusted.first(where: { $0.category == .walk })!.weight

        XCTAssertGreaterThan(readingWeight, 1.0, "Reading weight should increase in evening")
        XCTAssertLessThan(walkWeight, 1.0, "Walk weight should decrease at night")
    }

    func testTimeAdjustment_lunchTime_favorsGourmet() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .gourmet, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0),
        ]

        let adjusted = engine.applyTimeAdjustment(weights: weights, hour: 12)

        let gourmetWeight = adjusted.first(where: { $0.category == .gourmet })!.weight
        XCTAssertGreaterThan(gourmetWeight, 1.0, "Gourmet weight should increase at lunch time")
    }

    // MARK: - Duration Adjustment Tests

    func testDurationAdjustment_shortSlot_favorsReading() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .walk, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0),
        ]

        let adjusted = engine.applyDurationAdjustment(weights: weights, minutes: 20)

        let readingWeight = adjusted.first(where: { $0.category == .reading })!.weight
        let walkWeight = adjusted.first(where: { $0.category == .walk })!.weight

        XCTAssertGreaterThan(readingWeight, walkWeight, "Reading should be preferred for short time slots")
    }

    func testDurationAdjustment_shortSlot_penalizesMovie() {
        let weights = [
            SuggestionEngine.CategoryWeight(category: .movie, weight: 1.0),
            SuggestionEngine.CategoryWeight(category: .meditation, weight: 1.0),
        ]

        let adjusted = engine.applyDurationAdjustment(weights: weights, minutes: 20)

        let movieWeight = adjusted.first(where: { $0.category == .movie })!.weight
        let meditationWeight = adjusted.first(where: { $0.category == .meditation })!.weight

        XCTAssertLessThan(movieWeight, meditationWeight, "Movie should be heavily penalized for short slots")
    }

    // MARK: - Suggestion Generation Tests

    func testGenerateSuggestion_returnsValidSuggestion() {
        let slot = FreeTimeSlot(
            startDate: Date(),
            endDate: Date().adding(minutes: 60)
        )

        let weather = WeatherData(
            temperature: 20.0,
            condition: .clear,
            description: "晴れ",
            humidity: 45,
            windSpeed: 3.0,
            fetchedAt: Date()
        )

        let suggestion = engine.generateSuggestion(
            for: slot,
            weather: weather,
            preference: .default
        )

        XCTAssertFalse(suggestion.title.isEmpty)
        XCTAssertFalse(suggestion.description.isEmpty)
        XCTAssertGreaterThan(suggestion.duration, 0)
        XCTAssertEqual(suggestion.freeTimeSlot, slot)
    }

    func testGenerateAlternatives_excludesCategory() {
        let slot = FreeTimeSlot(
            startDate: Date(),
            endDate: Date().adding(minutes: 60)
        )

        let alternatives = engine.generateAlternatives(
            for: slot,
            weather: nil,
            preference: .default,
            excluding: .cafe
        )

        let hasCafe = alternatives.contains(where: { $0.category == .cafe })
        XCTAssertFalse(hasCafe, "Alternatives should not include the excluded category")
    }

    // MARK: - Weighted Random Selection

    func testWeightedRandomSelect_emptyWeights_returnsCafe() {
        let result = engine.weightedRandomSelect(from: [])
        XCTAssertEqual(result, .cafe)
    }

    func testWeightedRandomSelect_singleWeight_returnsThatCategory() {
        let weights = [SuggestionEngine.CategoryWeight(category: .reading, weight: 1.0)]
        let result = engine.weightedRandomSelect(from: weights)
        XCTAssertEqual(result, .reading)
    }

    // MARK: - Learning System Tests

    func testLearnedWeights_noHistory_equalWeights() {
        let preference = UserPreference.default
        let weights = preference.calculateLearnedWeights()

        let categoryCount = Double(SuggestionCategory.allCases.count)
        let expectedWeight = 1.0 / categoryCount

        for category in SuggestionCategory.allCases {
            XCTAssertEqual(weights[category]!, expectedWeight, accuracy: 0.01)
        }
    }

    func testLearnedWeights_withHistory_adjustsWeights() {
        var preference = UserPreference.default
        preference.selectionCounts = ["cafe": 3, "walk": 1]

        let weights = preference.calculateLearnedWeights()

        XCTAssertGreaterThan(weights[.cafe]!, weights[.walk]!, "Cafe should have higher weight after more selections")
        XCTAssertGreaterThan(weights[.cafe]!, weights[.reading]!, "Cafe should have higher weight than reading")
    }

    func testLearnedWeights_minimumGuarantee() {
        var preference = UserPreference.default
        preference.selectionCounts = ["cafe": 100]

        let weights = preference.calculateLearnedWeights()

        let categoryCount = Double(SuggestionCategory.allCases.count)
        let minimumWeight = max(0.05, 1.0 / (categoryCount * 3.0))

        for category in SuggestionCategory.allCases where category != .cafe {
            XCTAssertGreaterThanOrEqual(
                weights[category]!, minimumWeight,
                "\(category.displayName) should have at least minimum weight"
            )
        }
    }

    func testLearnedWeights_normalizedToOne() {
        var preference = UserPreference.default
        preference.selectionCounts = ["cafe": 5, "walk": 3, "reading": 2]

        let weights = preference.calculateLearnedWeights()
        let sum = weights.values.reduce(0, +)

        XCTAssertEqual(sum, 1.0, accuracy: 0.001, "Weights should sum to 1.0")
    }

    func testLearnedWeights_variableCategoryCount() {
        // Test with a subset of categories
        var preference = UserPreference.default
        preference.preferredCategories = [.cafe, .walk, .reading, .music, .art]
        preference.selectionCounts = ["cafe": 10]

        let weights = preference.calculateLearnedWeights()
        let sum = weights.values.reduce(0, +)

        XCTAssertEqual(sum, 1.0, accuracy: 0.001, "Weights should sum to 1.0 for any category count")
        XCTAssertEqual(weights.count, 5, "Should have weights for 5 categories")
    }

    func testLearnedWeights_dynamicMinimumWeight() {
        // 3 categories: minimum = max(0.05, 1/(3*3)) = 0.111
        var preference3 = UserPreference.default
        preference3.preferredCategories = [.cafe, .walk, .reading]
        preference3.selectionCounts = ["cafe": 100]

        let weights3 = preference3.calculateLearnedWeights()
        let min3 = max(0.05, 1.0 / (3.0 * 3.0))

        XCTAssertGreaterThanOrEqual(weights3[.walk]!, min3 - 0.001)

        // 10 categories: minimum = max(0.05, 1/(10*3)) = 0.05
        var preference10 = UserPreference.default
        preference10.selectionCounts = ["cafe": 100]

        let weights10 = preference10.calculateLearnedWeights()

        for category in SuggestionCategory.allCases where category != .cafe {
            XCTAssertGreaterThanOrEqual(weights10[category]!, 0.05 - 0.001)
        }
    }

    func testRecordSelection_incrementsCount() {
        var preference = UserPreference.default
        XCTAssertEqual(preference.selectionCount(for: .cafe), 0)

        preference.recordSelection(for: .cafe)
        XCTAssertEqual(preference.selectionCount(for: .cafe), 1)

        preference.recordSelection(for: .cafe)
        XCTAssertEqual(preference.selectionCount(for: .cafe), 2)

        preference.recordSelection(for: .walk)
        XCTAssertEqual(preference.selectionCount(for: .walk), 1)
    }

    func testRecordSelection_newCategories() {
        var preference = UserPreference.default

        preference.recordSelection(for: .music)
        XCTAssertEqual(preference.selectionCount(for: .music), 1)

        preference.recordSelection(for: .art)
        preference.recordSelection(for: .art)
        XCTAssertEqual(preference.selectionCount(for: .art), 2)
    }

    func testResetLearningData_clearsAllCounts() {
        var preference = UserPreference.default
        preference.selectionCounts = ["cafe": 5, "walk": 3, "reading": 2, "music": 1]

        preference.resetLearningData()

        XCTAssertEqual(preference.selectionCount(for: .cafe), 0)
        XCTAssertEqual(preference.selectionCount(for: .walk), 0)
        XCTAssertEqual(preference.selectionCount(for: .reading), 0)
        XCTAssertEqual(preference.selectionCount(for: .music), 0)
        XCTAssertEqual(preference.totalSelectionCount, 0)
    }

    func testCalculateWeights_usesLearnedWeights() {
        var preference = UserPreference.default
        preference.selectionCounts = ["cafe": 10]

        let slot = FreeTimeSlot(
            startDate: Date().setting(hour: 12),
            endDate: Date().setting(hour: 14)
        )

        let weights = engine.calculateWeights(
            weather: nil,
            preference: preference,
            slot: slot
        )

        let cafeWeight = weights.first(where: { $0.category == .cafe })!.weight
        let walkWeight = weights.first(where: { $0.category == .walk })!.weight

        XCTAssertGreaterThan(cafeWeight, walkWeight, "Cafe should have higher base weight from learning")
    }
}
