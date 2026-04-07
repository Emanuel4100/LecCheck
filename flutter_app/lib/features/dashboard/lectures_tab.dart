import 'package:flutter/material.dart';
import '../../core/platform/adaptive.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';
import 'lecture_card.dart';

enum LecturesSort {
  dateDesc,
  dateAsc,
  courseName,
  type,
  status,
}

class LecturesTab extends StatefulWidget {
  const LecturesTab({
    super.key,
    required this.schedule,
    required this.data,
    required this.showMeetingNumber,
    required this.l10n,
    required this.onStatus,
    required this.focusSearchToken,
  });

  final SemesterSchedule schedule;
  final List<Lecture> data;
  final bool showMeetingNumber;
  final AppLocalizations l10n;
  final void Function(Lecture, LectureStatus) onStatus;
  final int focusSearchToken;

  @override
  State<LecturesTab> createState() => _LecturesTabState();
}

class _LecturesTabState extends State<LecturesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  LecturesSort _sort = LecturesSort.dateDesc;
  bool _includeWeekAfter = false;
  int _lastFocusToken = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LecturesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusSearchToken != widget.focusSearchToken &&
        widget.focusSearchToken != _lastFocusToken) {
      _lastFocusToken = widget.focusSearchToken;
      _tabController.animateTo(2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocus.requestFocus();
        }
      });
    }
  }

  List<Lecture> _overduePending() {
    final now = DateTime.now();
    final list = widget.data
        .where(
          (l) =>
              lectureEndDateTime(l).isBefore(now) &&
              l.status == LectureStatus.pending,
        )
        .toList()
      ..sort(
        (a, b) => lectureEndDateTime(a).compareTo(lectureEndDateTime(b)),
      );
    return list;
  }

  List<Lecture> _upcoming() {
    final range = upcomingWeeksRange(
      DateTime.now(),
      widget.schedule.weekStartsOn,
      includeWeekAfter: _includeWeekAfter,
    );
    final list = widget.data
        .where(
          (l) => lectureStartInRange(
            l,
            range.startInclusive,
            range.endExclusive,
          ),
        )
        .toList()
      ..sort(
        (a, b) =>
            lectureStartDateTime(a).compareTo(lectureStartDateTime(b)),
      );
    return list;
  }

  List<Lecture> _allFilteredSorted() {
    final q = _searchQuery.trim().toLowerCase();
    Iterable<Lecture> it = widget.data;
    if (q.isNotEmpty) {
      it = it.where((l) {
        final name = l.courseName.toLowerCase();
        final disp =
            localizeCourseName(l.courseName, widget.l10n).toLowerCase();
        return name.contains(q) || disp.contains(q);
      });
    }
    final list = it.toList();
    switch (_sort) {
      case LecturesSort.dateDesc:
        list.sort((a, b) {
          final c = b.date.compareTo(a.date);
          return c != 0 ? c : b.start.compareTo(a.start);
        });
      case LecturesSort.dateAsc:
        list.sort((a, b) {
          final c = a.date.compareTo(b.date);
          return c != 0 ? c : a.start.compareTo(b.start);
        });
      case LecturesSort.courseName:
        list.sort(
          (a, b) => a.courseName.toLowerCase().compareTo(
                b.courseName.toLowerCase(),
              ),
        );
      case LecturesSort.type:
        list.sort((a, b) => a.type.compareTo(b.type));
      case LecturesSort.status:
        list.sort((a, b) => a.status.index.compareTo(b.status.index));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final overdue = _overduePending();
    final upcoming = _upcoming();
    final allList = _allFilteredSorted();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.lecturesTabNeedAttention),
            Tab(text: l10n.lecturesTabUpcoming),
            Tab(text: l10n.lecturesTabAll),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LectureListPane(
                lectures: overdue,
                emptyIcon: Icons.check_circle_outline,
                emptyTitle: l10n.lecturesCaughtUpTitle,
                emptySubtitle: l10n.lecturesCaughtUpSubtitle,
                footerHint: overdue.isEmpty
                    ? null
                    : l10n.lecturesMarkToKeepStreakHint,
                showMeetingNumber: widget.showMeetingNumber,
                allLectures: widget.data,
                l10n: l10n,
                onStatus: widget.onStatus,
              ),
              _UpcomingPane(
                lectures: upcoming,
                includeWeekAfter: _includeWeekAfter,
                onToggleWeekAfter: () =>
                    setState(() => _includeWeekAfter = !_includeWeekAfter),
                l10n: l10n,
                showMeetingNumber: widget.showMeetingNumber,
                allLectures: widget.data,
                onStatus: widget.onStatus,
              ),
              _AllLecturesPane(
                lectures: allList,
                searchFocus: _searchFocus,
                searchController: _searchCtrl,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                sort: _sort,
                onSortChanged: (s) => setState(() => _sort = s),
                showMeetingNumber: widget.showMeetingNumber,
                allLectures: widget.data,
                l10n: l10n,
                onStatus: widget.onStatus,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LectureListPane extends StatelessWidget {
  const _LectureListPane({
    required this.lectures,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.footerHint,
    required this.showMeetingNumber,
    required this.allLectures,
    required this.l10n,
    required this.onStatus,
  });

  final List<Lecture> lectures;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String? footerHint;
  final bool showMeetingNumber;
  final List<Lecture> allLectures;
  final AppLocalizations l10n;
  final void Function(Lecture, LectureStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    if (lectures.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(emptyIcon, size: 56, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (footerHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              footerHint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: lectures.length,
            itemBuilder: (_, i) => LectureCard(
              lecture: lectures[i],
              allLectures: allLectures,
              showMeetingNumber: showMeetingNumber,
              l10n: l10n,
              onStatus: onStatus,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingPane extends StatelessWidget {
  const _UpcomingPane({
    required this.lectures,
    required this.includeWeekAfter,
    required this.onToggleWeekAfter,
    required this.l10n,
    required this.showMeetingNumber,
    required this.allLectures,
    required this.onStatus,
  });

  final List<Lecture> lectures;
  final bool includeWeekAfter;
  final VoidCallback onToggleWeekAfter;
  final AppLocalizations l10n;
  final bool showMeetingNumber;
  final List<Lecture> allLectures;
  final void Function(Lecture, LectureStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: lectures.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.lecturesNoUpcoming,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: lectures.length,
                  itemBuilder: (_, i) => LectureCard(
                    lecture: lectures[i],
                    allLectures: allLectures,
                    showMeetingNumber: showMeetingNumber,
                    l10n: l10n,
                    onStatus: onStatus,
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: onToggleWeekAfter,
            child: Text(
              includeWeekAfter
                  ? l10n.showNextWeekOnly
                  : l10n.showNextWeekToo,
            ),
          ),
        ),
      ],
    );
  }
}

class _AllLecturesPane extends StatelessWidget {
  const _AllLecturesPane({
    required this.lectures,
    required this.searchFocus,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sort,
    required this.onSortChanged,
    required this.showMeetingNumber,
    required this.allLectures,
    required this.l10n,
    required this.onStatus,
  });

  final List<Lecture> lectures;
  final FocusNode searchFocus;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final LecturesSort sort;
  final ValueChanged<LecturesSort> onSortChanged;
  final bool showMeetingNumber;
  final List<Lecture> allLectures;
  final AppLocalizations l10n;
  final void Function(Lecture, LectureStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    final stackSearchSort = Adaptive.isCompactPhone(context) ||
        MediaQuery.sizeOf(context).width < 520;

    final searchField = TextField(
      controller: searchController,
      focusNode: searchFocus,
      decoration: InputDecoration(
        hintText: l10n.searchCourses,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onSearchChanged,
    );

    final sortButton = PopupMenuButton<LecturesSort>(
      tooltip: l10n.sortMenuTooltip,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: LecturesSort.dateDesc,
          child: Text(l10n.sortByDateNewest),
        ),
        PopupMenuItem(
          value: LecturesSort.dateAsc,
          child: Text(l10n.sortByDateOldest),
        ),
        PopupMenuItem(
          value: LecturesSort.courseName,
          child: Text(l10n.sortByCourse),
        ),
        PopupMenuItem(
          value: LecturesSort.type,
          child: Text(l10n.sortByType),
        ),
        PopupMenuItem(
          value: LecturesSort.status,
          child: Text(l10n.sortByStatus),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.sortMenuTooltip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: stackSearchSort
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: sortButton,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    sortButton,
                  ],
                ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: lectures.length,
            itemBuilder: (_, i) => LectureCard(
              lecture: lectures[i],
              allLectures: allLectures,
              showMeetingNumber: showMeetingNumber,
              l10n: l10n,
              onStatus: onStatus,
            ),
          ),
        ),
      ],
    );
  }
}
