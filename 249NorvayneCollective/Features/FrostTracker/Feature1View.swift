import SwiftUI

struct Feature1View: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel: Feature1ViewModel
    @State private var showRangeEditor = false

    init(bottomInset: CGFloat) {
        self.bottomInset = bottomInset
        _viewModel = StateObject(wrappedValue: Feature1ViewModel(store: AppStorageStore.shared))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        heroBanner

                        quickActionsRow

                        citySearchCard

                        if let day = viewModel.dayMinC, let night = viewModel.nightMinC {
                            RiskHeroCard(
                                cityLabel: viewModel.selectedCityLabel,
                                dayText: store.displayTemperature(day),
                                nightText: store.displayTemperature(night),
                                dayRisky: day <= 0,
                                nightRisky: night <= 0,
                                assetsLine: assetsRiskLine(day: day, night: night)
                            )
                        } else {
                            emptyRiskPrompt
                        }

                        forecastControlsCard

                        if let statusMessage = viewModel.statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        chartCard

                        PrimaryButton(
                            title: viewModel.isLoadingForecast ? "Updating…" : "Update Forecast",
                            isLoading: viewModel.isLoadingForecast
                        ) {
                            viewModel.updateForecast()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()

                if viewModel.showSuccessBadge {
                    SuccessCheckBadge()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $viewModel.selectedPoint) { point in
                ForecastDetailSheet(point: point, store: store)
            }
            .sheet(isPresented: $showRangeEditor) {
                rangeEditorSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                viewModel.reloadFromStore()
            }
        }
        .transparentScreenChrome()
    }

    // MARK: - Hero

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            Image("FrostHeroNight")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.05),
                    Color("AppBackground").opacity(0.55),
                    Color("AppBackground").opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                StatusPill(
                    text: heroStatusText,
                    isWarning: (viewModel.nightMinC ?? 99) <= 0
                )

                Text("Frost Risk Tracker")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(viewModel.selectedCityLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(2)

                if let night = viewModel.nightMinC {
                    Text("Tonight low \(store.displayTemperature(night))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color("AppSurface").opacity(0.85))
                        )
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("AppTextPrimary").opacity(0.22),
                            Color("AppTextPrimary").opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: DepthStyle.shadowColor, radius: 12, y: 6)
    }

    private var heroStatusText: String {
        guard let night = viewModel.nightMinC else { return "Set city & update" }
        if night <= -3 { return "Hard freeze risk" }
        if night <= 0 { return "Frost likely tonight" }
        return "Above freezing"
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            HomeImageActionCard(
                imageName: "FrostThermometer",
                title: "Tonight Risk",
                subtitle: viewModel.nightMinC.map(store.displayTemperature) ?? "Update",
                accentWarning: (viewModel.nightMinC ?? 99) <= 0
            ) {
                HapticFeedback.lightTap()
                viewModel.updateForecast()
            }

            HomeImageActionCard(
                imageName: "FrostProtectAssets",
                title: "Protect Assets",
                subtitle: "\(store.protectableAssets.count) watched",
                accentWarning: false
            ) {
                HapticFeedback.lightTap()
                store.rebuildTonightChecklist()
                viewModel.statusMessage = "Tonight checklist rebuilt from current assets and forecast."
                HapticFeedback.updateAcknowledged()
            }
        }
    }

    private var emptyRiskPrompt: some View {
        AppCard {
            HStack(spacing: 14) {
                Image("FrostThermometer")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("No live risk yet")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Choose a city and tap Update Forecast to load day/night lows.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                }
            }
        }
    }

    // MARK: - City / controls / chart

    private func assetsRiskLine(day: Double, night: Double) -> String {
        let atRisk = store.assetsAtRisk(forNightMin: night, dayMin: day)
        if atRisk.isEmpty {
            return "No saved assets are below their personal thresholds."
        }
        return "At risk: " + atRisk.map(\.name).joined(separator: ", ")
    }

    private var citySearchCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    IconBadge(systemName: "mappin.and.ellipse", tint: Color("AppPrimary"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("City / Region")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(viewModel.selectedCityLabel)
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                            .lineLimit(2)
                    }
                }

                HStack(spacing: 10) {
                    TextField("Search city (no location needed)", text: $viewModel.cityQuery)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("AppBackground").opacity(0.55))
                        )
                        .onChange(of: viewModel.cityQuery) { _ in
                            viewModel.searchCitiesDebounced()
                        }

                    if viewModel.isSearchingCity {
                        ProgressView()
                            .tint(Color("AppAccent"))
                            .frame(width: 44, height: 44)
                    }
                }

                if !viewModel.cityResults.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.cityResults) { result in
                            Button {
                                viewModel.selectCity(result)
                            } label: {
                                HStack(spacing: 12) {
                                    IconBadge(systemName: "building.2.fill", tint: Color("AppAccent"), size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .lineLimit(1)
                                        Text([result.admin1, result.country].filter { !$0.isEmpty }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("AppBackground").opacity(0.4))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var forecastControlsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Forecast Range")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button {
                        HapticFeedback.lightTap()
                        showRangeEditor = true
                    } label: {
                        Label("Edit", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color("AppBackground").opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                }

                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(Feature1ViewModel.Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.mode) { _ in
                    HapticFeedback.lightTap()
                }

                HStack(spacing: 10) {
                    MetricChip(
                        title: "From",
                        value: viewModel.rangeStart.formatted(date: .abbreviated, time: .omitted)
                    )
                    MetricChip(
                        title: "To",
                        value: viewModel.rangeEnd.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                unitToggle

                if let dateError = viewModel.dateError {
                    Text(dateError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .modifier(ShakeEffect(animatableData: CGFloat(viewModel.shakeDates)))
                }
            }
        }
    }

    private var unitToggle: some View {
        HStack {
            Text("Temperature Unit")
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Picker("Unit", selection: $store.preferredTemperatureUnit) {
                Text("°C").tag("C")
                Text("°F").tag("F")
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 140)
            .onChange(of: store.preferredTemperatureUnit) { _ in
                HapticFeedback.lightTap()
            }
        }
    }

    private var chartCard: some View {
        AppCard(accentBorder: viewModel.chartPulse) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(viewModel.isEmpty ? "No forecasts available" : "Temperature Trend")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    if !viewModel.isEmpty {
                        StatusPill(text: "\(viewModel.points.count) days")
                    }
                }

                if viewModel.isEmpty {
                    ZStack(alignment: .bottomLeading) {
                        Image("FrostProtectAssets")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .opacity(0.55)

                        LinearGradient(
                            colors: [Color.clear, Color("AppSurface")],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Explore future forecasts")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Choose a city, pick dates, then update.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .padding(14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    GeometryReader { geo in
                        TemperatureLineChart(
                            points: viewModel.points,
                            pulse: viewModel.chartPulse
                        )
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    viewModel.selectPoint(at: value.location.x, width: geo.size.width)
                                }
                        )
                    }
                    .frame(height: 220)

                    Text("Drag the chart to inspect a day")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.chartPulse)
    }

    private var rangeEditorSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    AppCard {
                        VStack(spacing: 14) {
                            DatePicker("From", selection: $viewModel.rangeStart, displayedComponents: .date)
                                .tint(Color("AppAccent"))
                                .colorScheme(.dark)
                            DatePicker("To", selection: $viewModel.rangeEnd, displayedComponents: .date)
                                .tint(Color("AppAccent"))
                                .colorScheme(.dark)
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        HapticFeedback.lightTap()
                        showRangeEditor = false
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Home image action card

private struct HomeImageActionCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    var accentWarning: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color("AppBackground").opacity(0.75),
                        Color("AppBackground").opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accentWarning ? Color("AppAccent") : Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: accentWarning
                            ? [Color("AppAccent").opacity(0.7), Color("AppAccent").opacity(0.2)]
                            : [Color("AppTextPrimary").opacity(0.2), Color("AppTextPrimary").opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: accentWarning ? 1.5 : 1
                    )
            )
            .shadow(color: DepthStyle.softShadowColor, radius: 8, y: 4)
            .appPressScale(pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

// MARK: - Chart + detail

struct TemperatureLineChart: View {
    let points: [ForecastPoint]
    var pulse: Bool = false

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }

            let temps = points.map(\.temperature)
            let minT = (temps.min() ?? -5) - 2
            let maxT = (temps.max() ?? 10) + 2
            let range = max(maxT - minT, 1)

            let zeroY = size.height - CGFloat((0 - minT) / range) * size.height
            var zeroPath = Path()
            zeroPath.move(to: CGPoint(x: 0, y: zeroY))
            zeroPath.addLine(to: CGPoint(x: size.width, y: zeroY))
            context.stroke(zeroPath, with: .color(Color("AppTextSecondary").opacity(0.35)), lineWidth: 1)

            var line = Path()
            for (index, point) in points.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(points.count - 1)
                let y = size.height - CGFloat((point.temperature - minT) / range) * size.height
                if index == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                line,
                with: .color(pulse ? Color("AppAccent") : Color("AppPrimary")),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )

            for (index, point) in points.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(points.count - 1)
                let y = size.height - CGFloat((point.temperature - minT) / range) * size.height
                let color = point.isFrostRisk ? Color("AppAccent") : Color("AppTextPrimary")
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: points.map(\.id))
    }
}

private struct ForecastDetailSheet: View {
    let point: ForecastPoint
    let store: AppStorageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("FrostHeroNight")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        AppCard(accentBorder: point.isFrostRisk) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    IconBadge(
                                        systemName: point.isFrostRisk ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                                        tint: point.isFrostRisk ? Color("AppAccent") : Color("AppPrimary")
                                    )
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(point.isFrostRisk ? "Frost Risk" : "Safe Range")
                                            .font(.headline)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        Text(point.date.formatted(date: .complete, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                                MetricChip(
                                    title: "Temperature",
                                    value: store.displayTemperature(point.temperature),
                                    emphasize: point.isFrostRisk
                                )
                                Text(point.isFrostRisk
                                     ? "Protect plants, outdoor pipes, and sensitive equipment overnight."
                                     : "No freezing expected for this day based on the forecast.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Day Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
