import SwiftUI

// MARK: - Timeline (Gantt)
struct TimelineView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedProject: Project?
    @State private var showCalendar = false

    var project: Project? { selectedProject ?? dataStore.activeProject }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Project selector
                if dataStore.projects.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(dataStore.projects) { proj in
                                Button(action: { selectedProject = proj }) {
                                    Text(proj.name).font(.btSubhead())
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(project?.id == proj.id ? Color.btPrimary : Color(.systemGray6))
                                        .foregroundColor(project?.id == proj.id ? .white : .primary)
                                        .cornerRadius(20)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if let proj = project {
                    // Header card
                    BTCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(proj.name).font(.btHeadline()).foregroundColor(.primary)
                                    Text("\(proj.phases.count) phases · \(proj.progress.btPercent()) complete")
                                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                                }
                                Spacer()
                                BTBadge(label: proj.isCompleted ? "Done" : "Active",
                                        color: proj.isCompleted ? .btSuccess : .btInfo)
                            }
                            BTProgressBar(progress: proj.progress, height: 8)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Gantt chart
                    GanttChart(project: proj)
                        .padding(.horizontal, 16)

                    // Phase list with dates
                    VStack(spacing: 10) {
                        BTSectionHeader(title: "Phase Details")
                            .padding(.horizontal, 16)

                        ForEach(proj.phases.sorted { $0.order < $1.order }) { phase in
                            PhaseTimelineRow(phase: phase, project: proj)
                                .padding(.horizontal, 16)
                        }
                    }

                    // Calendar button
                    BTButton(title: "View Calendar", icon: "calendar",
                             style: .outline) { showCalendar = true }
                        .padding(.horizontal, 16)

                } else {
                    BTCard {
                        BTEmptyState(icon: "chart.bar.xaxis",
                                     title: "No Project Found",
                                     subtitle: "Create a project first to see the timeline.")
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCalendar) {
            if let proj = project { CalendarView(project: proj) }
        }
    }
}

// MARK: - Gantt Chart
struct GanttChart: View {
    let project: Project

    var allDates: (min: Date, max: Date) {
        let phases = project.phases.filter { $0.startDate != nil || $0.endDate != nil }
        var dates: [Date] = []
        phases.forEach { ph in
            if let s = ph.startDate { dates.append(s) }
            if let e = ph.endDate   { dates.append(e) }
        }
        if let start = project.endDate { dates.append(start) }
        dates.append(project.startDate)
        let min = dates.min() ?? project.startDate
        let max = dates.max() ?? Date().addingTimeInterval(86400 * 90)
        return (min, max)
    }

    var totalDays: Double {
        max(1, allDates.max.timeIntervalSince(allDates.min) / 86400)
    }

    var body: some View {
        BTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Gantt View").font(.btHeadline()).foregroundColor(.primary)

                // Month labels
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Month markers
                        let cal = Calendar.current
                        let months = monthMarkers()
                        ForEach(months.indices, id: \.self) { i in
                            let pct = months[i].offset / totalDays
                            Text(months[i].label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.btTextSecondary)
                                .offset(x: geo.size.width * CGFloat(pct))
                        }
                        // Today line
                        let todayPct = Date().timeIntervalSince(allDates.min) / (totalDays * 86400)
                        if todayPct >= 0 && todayPct <= 1 {
                            Rectangle()
                                .fill(Color.btDanger)
                                .frame(width: 2, height: 100)
                                .offset(x: geo.size.width * CGFloat(todayPct))
                        }
                        let _ = cal.component(.month, from: Date())
                    }
                }
                .frame(height: 16)

                // Phase bars
                ForEach(project.phases.sorted { $0.order < $1.order }) { phase in
                    GanttBar(phase: phase, minDate: allDates.min, totalDays: totalDays)
                }

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .btPrimary, label: "Active Phase")
                    legendItem(color: .btSuccess, label: "Completed")
                    Circle().fill(Color.btDanger).frame(width: 8, height: 8)
                    Text("Today").font(.btCaption()).foregroundColor(.btTextSecondary)
                }
            }
        }
    }

    func monthMarkers() -> [(label: String, offset: Double)] {
        var result: [(String, Double)] = []
        let cal = Calendar.current
        var current = cal.date(from: cal.dateComponents([.year, .month], from: allDates.min))!
        let f = DateFormatter(); f.dateFormat = "MMM"
        while current <= allDates.max {
            let offset = current.timeIntervalSince(allDates.min) / 86400
            result.append((f.string(from: current), offset))
            current = cal.date(byAdding: .month, value: 1, to: current)!
        }
        return result
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 16, height: 8)
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
        }
    }
}

struct GanttBar: View {
    let phase: Phase
    let minDate: Date
    let totalDays: Double

    var startPct: Double {
        guard let s = phase.startDate else { return 0 }
        return max(0, min(1, s.timeIntervalSince(minDate) / (totalDays * 86400)))
    }
    var widthPct: Double {
        guard let s = phase.startDate, let e = phase.endDate else { return 0.15 }
        let days = e.timeIntervalSince(s) / 86400
        return max(0.02, min(1 - startPct, days / totalDays))
    }
    var barColor: Color {
        phase.isCompleted ? .btSuccess : Color.phaseColor(for: phase.name)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(phase.name)
                .font(.btCaption2()).fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 20)

                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor.opacity(0.85))
                        .frame(
                            width: geo.size.width * CGFloat(widthPct),
                            height: 20
                        )
                        .offset(x: geo.size.width * CGFloat(startPct))

                    // Completion overlay
                    if phase.progress > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(
                                width: geo.size.width * CGFloat(widthPct) * CGFloat(phase.progress),
                                height: 20
                            )
                            .offset(x: geo.size.width * CGFloat(startPct))
                    }
                }
            }
            .frame(height: 20)

            Text(phase.progress.btPercent())
                .font(.btCaption2()).foregroundColor(barColor)
                .frame(width: 36)
        }
    }
}

// MARK: - Phase Timeline Row
struct PhaseTimelineRow: View {
    let phase: Phase
    let project: Project

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                // Status dot
                ZStack {
                    Circle().fill(phase.isCompleted ? Color.btSuccess.opacity(0.15) : Color.phaseColor(for: phase.name).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: phase.isCompleted ? "checkmark.circle.fill" : phaseIcon(for: phase.name))
                        .font(.system(size: 15))
                        .foregroundColor(phase.isCompleted ? .btSuccess : Color.phaseColor(for: phase.name))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.name).font(.btSubhead()).foregroundColor(.primary)
                    if let s = phase.startDate, let e = phase.endDate {
                        Text("\(s.btShort) → \(e.btShort)")
                            .font(.btCaption()).foregroundColor(.btTextSecondary)
                    } else if let s = phase.startDate {
                        Text("From \(s.btShort)").font(.btCaption()).foregroundColor(.btTextSecondary)
                    } else {
                        Text("No dates set").font(.btCaption()).foregroundColor(.btTextSecondary.opacity(0.6))
                    }
                }

                Spacer()
                Text(phase.progress.btPercent())
                    .font(.btSubhead()).fontWeight(.semibold)
                    .foregroundColor(Color.phaseColor(for: phase.name))
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @Environment(\.presentationMode) var dismiss
    @EnvironmentObject var dataStore: DataStore
    let project: Project

    @State private var displayMonth = Date()
    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation
                HStack {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.btPrimary)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.btTitle3()).foregroundColor(.primary)
                    Spacer()
                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.btPrimary)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Day headers
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                            ForEach(dayHeaders, id: \.self) { d in
                                Text(d).font(.btCaption2()).fontWeight(.semibold)
                                    .foregroundColor(.btTextSecondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12).padding(.top, 12)

                        // Days grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(calendarDays, id: \.self) { date in
                                CalendarDayCell(date: date,
                                                displayMonth: displayMonth,
                                                taskDeadlines: deadlineMap,
                                                phaseRanges: phaseRanges)
                            }
                        }
                        .padding(.horizontal, 12)

                        // Legend
                        HStack(spacing: 20) {
                            legendDot(color: .btPrimary,  label: "Task deadline")
                            legendDot(color: .btInfo,     label: "Phase dates")
                            legendDot(color: .btDanger,   label: "Today")
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 20)
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        displayMonth = Date()
                    }.foregroundColor(.btPrimary)
                }
            }
        }
    }

    var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth)
    }
    var dayHeaders: [String] { ["Su","Mo","Tu","We","Th","Fr","Sa"] }

    var calendarDays: [Date] {
        let start = calendar.date(from: calendar.dateComponents([.year,.month], from: displayMonth))!
        let weekday = calendar.component(.weekday, from: start) - 1
        let startPad = calendar.date(byAdding: .day, value: -weekday, to: start)!
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: startPad) }
    }

    // Map of dates with task deadlines
    var deadlineMap: Set<String> {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        var set = Set<String>()
        project.phases.forEach { ph in
            ph.tasks.forEach { task in
                if let d = task.deadline, !task.isCompleted { set.insert(f.string(from: d)) }
            }
        }
        return set
    }

    // Phase date ranges for highlight
    var phaseRanges: [(start: Date, end: Date)] {
        project.phases.compactMap { ph in
            guard let s = ph.startDate, let e = ph.endDate else { return nil }
            return (s, e)
        }
    }

    func changeMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: displayMonth) {
            displayMonth = d
        }
    }

    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let displayMonth: Date
    let taskDeadlines: Set<String>
    let phaseRanges: [(start: Date, end: Date)]

    private let calendar = Calendar.current
    private let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    var isCurrentMonth: Bool { calendar.component(.month, from: date) == calendar.component(.month, from: displayMonth) }
    var isToday: Bool { calendar.isDateInToday(date) }
    var hasDeadline: Bool { taskDeadlines.contains(formatter.string(from: date)) }
    var isInPhase: Bool { phaseRanges.contains { date >= $0.start && date <= $0.end } }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isToday ? Color.btDanger :
                          isInPhase ? Color.btInfo.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(isToday ? .white :
                                     isCurrentMonth ? .primary : .btTextSecondary.opacity(0.35))
            }

            // Deadline dot
            if hasDeadline && isCurrentMonth {
                Circle().fill(Color.btPrimary).frame(width: 5, height: 5)
            } else {
                Color.clear.frame(width: 5, height: 5)
            }
        }
        .frame(height: 44)
    }
}
