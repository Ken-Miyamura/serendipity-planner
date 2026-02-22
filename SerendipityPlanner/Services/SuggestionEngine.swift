import Foundation

class SuggestionEngine: SuggestionEngineProtocol {

    struct CategoryWeight {
        let category: SuggestionCategory
        var weight: Double
    }

    /// Generate a suggestion for a given free time slot based on weather and user preferences
    func generateSuggestion(
        for slot: FreeTimeSlot,
        weather: WeatherData?,
        preference: UserPreference
    ) -> Suggestion {
        let weights = calculateWeights(
            weather: weather,
            preference: preference,
            slot: slot
        )

        let selectedCategory = weightedRandomSelect(from: weights)
        let template = selectTemplate(for: selectedCategory, duration: slot.durationMinutes)
        let weatherContext = weatherContextText(weather: weather, category: selectedCategory)

        return Suggestion(
            category: selectedCategory,
            title: template.title,
            description: template.description,
            duration: min(template.minDuration, slot.durationMinutes),
            freeTimeSlot: slot,
            weatherContext: weatherContext
        )
    }

    /// Generate multiple suggestions for a time slot (for re-suggestion)
    func generateAlternatives(
        for slot: FreeTimeSlot,
        weather: WeatherData?,
        preference: UserPreference,
        excluding: SuggestionCategory? = nil
    ) -> [Suggestion] {
        let categories = preference.preferredCategories.filter { $0 != excluding }
        return categories.compactMap { category in
            let templates = SuggestionTemplates.templates(for: category)
            guard let template = templates.filter({ $0.minDuration <= slot.durationMinutes }).randomElement()
                    ?? templates.first else { return nil }

            let weatherContext = weatherContextText(weather: weather, category: category)

            return Suggestion(
                category: category,
                title: template.title,
                description: template.description,
                duration: min(template.minDuration, slot.durationMinutes),
                freeTimeSlot: slot,
                weatherContext: weatherContext
            )
        }
    }

    // MARK: - Weight Calculation

    func calculateWeights(
        weather: WeatherData?,
        preference: UserPreference,
        slot: FreeTimeSlot
    ) -> [CategoryWeight] {
        // Start with learned weights from user selection history
        let learnedWeights = preference.calculateLearnedWeights()
        var weights = preference.preferredCategories.map { category in
            let defaultWeight = 1.0 / Double(preference.preferredCategories.count)
            return CategoryWeight(category: category, weight: learnedWeights[category] ?? defaultWeight)
        }

        // Apply weather adjustments
        if let weather = weather {
            weights = applyWeatherAdjustment(weights: weights, weather: weather)
        }

        // Apply time-of-day adjustments
        weights = applyTimeAdjustment(weights: weights, hour: slot.startDate.hour)

        // Apply duration adjustments
        weights = applyDurationAdjustment(weights: weights, minutes: slot.durationMinutes)

        return weights
    }

    func applyWeatherAdjustment(weights: [CategoryWeight], weather: WeatherData) -> [CategoryWeight] {
        weights.map { item in
            var adjusted = item
            let profile = item.category.weightProfile

            if weather.condition.isOutdoorFriendly {
                adjusted.weight *= profile.outdoorFriendlyMultiplier
            } else {
                adjusted.weight *= profile.outdoorUnfriendlyMultiplier
            }

            if weather.temperature >= 15 && weather.temperature <= 25 {
                adjusted.weight *= profile.comfortableTempMultiplier
            } else if weather.temperature < 10 || weather.temperature > 30 {
                adjusted.weight *= profile.coldOrHotMultiplier
            }

            return adjusted
        }
    }

    func applyTimeAdjustment(weights: [CategoryWeight], hour: Int) -> [CategoryWeight] {
        weights.map { item in
            var adjusted = item
            let profile = item.category.weightProfile

            let isPreferred = profile.preferredHourRanges.contains { $0.contains(hour) }
            if isPreferred {
                adjusted.weight *= profile.preferredHourMultiplier
            }

            let isPenalty = profile.penaltyHourRanges.contains { $0.contains(hour) }
            if isPenalty {
                adjusted.weight *= profile.penaltyHourMultiplier
            }

            return adjusted
        }
    }

    func applyDurationAdjustment(weights: [CategoryWeight], minutes: Int) -> [CategoryWeight] {
        weights.map { item in
            var adjusted = item
            if minutes < 30 {
                adjusted.weight *= item.category.weightProfile.shortSlotMultiplier
            }
            return adjusted
        }
    }

    // MARK: - Selection

    func weightedRandomSelect(from weights: [CategoryWeight]) -> SuggestionCategory {
        guard !weights.isEmpty else { return .cafe }

        let totalWeight = weights.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return weights[0].category }

        let random = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0

        for item in weights {
            cumulative += item.weight
            if random < cumulative {
                return item.category
            }
        }

        return weights.last!.category
    }

    private func selectTemplate(
        for category: SuggestionCategory,
        duration: Int
    ) -> SuggestionTemplates.Template {
        let templates = SuggestionTemplates.templates(for: category)
        let fitting = templates.filter { $0.minDuration <= duration }
        return fitting.randomElement() ?? templates[0]
    }

    private func weatherContextText(weather: WeatherData?, category: SuggestionCategory) -> String {
        guard let weather = weather else {
            return "天気情報を取得できませんでした"
        }

        let format = category.weatherContextFormat
        let weatherSummary = "\(weather.condition.displayName)で\(weather.temperatureText)"

        if weather.condition.isOutdoorFriendly {
            return String(format: format.outdoor, weatherSummary)
        } else {
            return String(format: format.indoor, weather.condition.displayName)
        }
    }
}
