import SwiftUI

struct ProtectionPlansSection: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @State private var selectedPlan: ProtectionPlan?
    @State private var showEditor = false
    @State private var draftTitle = ""
    @State private var draftStepsText = ""
    @State private var titleError: String?
    @State private var shakeTitle = 0

    var body: some View {
        Group {
            if store.protectionPlans.isEmpty {
                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(
                            title: "Protection Plans",
                            subtitle: "Step-by-step actions for frost nights"
                        )
                        EmptyStateView(
                            symbolName: "list.clipboard",
                            title: "No protection plans",
                            message: "Create step-by-step actions for frost nights."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .clearScrollBackground()
            } else {
                List {
                    Section {
                        SectionHeaderView(
                            title: "Protection Plans",
                            subtitle: "Swipe to use tonight or delete",
                            trailing: "\(store.protectionPlans.count)"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(store.protectionPlans) { plan in
                        Button {
                            HapticFeedback.lightTap()
                            selectedPlan = plan
                        } label: {
                            PlanCell(
                                title: plan.title,
                                stepCount: plan.steps.count,
                                kindTitle: plan.linkedKind?.title,
                                isTemplate: plan.isTemplate
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(plan)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                applyPlanToTonight(plan)
                            } label: {
                                Label("Use Tonight", systemImage: "moon.stars")
                            }
                            .tint(Color("AppPrimary"))
                        }
                    }
                }
                .listStyle(.plain)
                .clearScrollBackground()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Add Custom Plan") {
                beginCreate()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, bottomInset)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0),
                        Color("AppBackground").opacity(0.92),
                        Color("AppBackground")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(item: $selectedPlan) { plan in
            planDetail(plan)
        }
        .sheet(isPresented: $showEditor) {
            planEditor
        }
    }

    private func planDetail(_ plan: ProtectionPlan) -> some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PlanCell(
                            title: plan.title,
                            stepCount: plan.steps.count,
                            kindTitle: plan.linkedKind?.title,
                            isTemplate: plan.isTemplate
                        )

                        ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                            AppCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color("AppPrimary")))
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                        }

                        PrimaryButton(title: "Add Steps to Tonight") {
                            applyPlanToTonight(plan)
                            selectedPlan = nil
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Protection Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        selectedPlan = nil
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var planEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Plan title", text: $draftTitle)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.5)))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .modifier(ShakeEffect(animatableData: CGFloat(shakeTitle)))

                                if let titleError {
                                    Text(titleError)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }

                                Text("One step per line")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))

                                TextEditor(text: $draftStepsText)
                                    .frame(minHeight: 160)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.5)))
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }

                        PrimaryButton(title: "Save Plan") {
                            savePlan()
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Custom Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        showEditor = false
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func beginCreate() {
        HapticFeedback.lightTap()
        draftTitle = ""
        draftStepsText = "Stage covers near the door\nCheck vulnerable assets before dusk"
        titleError = nil
        showEditor = true
    }

    private func savePlan() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let steps = draftStepsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !title.isEmpty else {
            titleError = "Enter a plan title."
            shakeTitle += 1
            HapticFeedback.warning()
            return
        }
        guard !steps.isEmpty else {
            titleError = "Add at least one step."
            shakeTitle += 1
            HapticFeedback.warning()
            return
        }

        HapticFeedback.mediumTap()
        store.protectionPlans.insert(
            ProtectionPlan(title: title, steps: steps, linkedKind: nil, isTemplate: false),
            at: 0
        )
        store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: false)
        HapticFeedback.success()
        showEditor = false
    }

    private func applyPlanToTonight(_ plan: ProtectionPlan) {
        HapticFeedback.mediumTap()
        var items = store.tonightChecklist
        for step in plan.steps {
            if !items.contains(where: { $0.title == step }) {
                items.append(TonightChecklistItem(title: step, relatedPlanID: plan.id))
            }
        }
        store.tonightChecklist = items
        store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: true)
        HapticFeedback.success()
    }

    private func delete(_ plan: ProtectionPlan) {
        HapticFeedback.lightTap()
        store.protectionPlans.removeAll { $0.id == plan.id }
    }
}
