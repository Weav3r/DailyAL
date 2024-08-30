import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dailyanimelist/api/dalapi.dart';
import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/pages/animedetailed/synopsiswidget.dart';
import 'package:dailyanimelist/screens/contentdetailedscreen.dart';
import 'package:dailyanimelist/util/streamutils.dart';
import 'package:dailyanimelist/widgets/avatarwidget.dart';
import 'package:dailyanimelist/widgets/custombutton.dart';
import 'package:dailyanimelist/widgets/customfuture.dart';
import 'package:dailyanimelist/widgets/slivers.dart';
import 'package:dal_commons/commons.dart';
import 'package:flutter/material.dart';

import '../../api/malapi.dart';

class _SchduledNode {
  final int dayofWeek;
  final ScheduleData scheduleData;
  final Node anime;
  final bool currentDay;

  _SchduledNode(
    this.dayofWeek,
    this.scheduleData,
    this.anime, {
    this.currentDay = false,
  });

  static _SchduledNode _currentDayNode() {
    final now = DateTime.now();
    return _SchduledNode(
      now.weekday,
      ScheduleData(timestamp: now.millisecondsSinceEpoch ~/ 1000),
      Node(),
      currentDay: true,
    );
  }
}

class _Filter {
  final String displayText;
  final String value;
  bool isApplied = true;

  _Filter({required this.displayText, required this.value});
}

class AnimeCalendarWidget extends StatefulWidget {
  const AnimeCalendarWidget({Key? key}) : super(key: key);

  @override
  State<AnimeCalendarWidget> createState() => _AnimeCalendarWidgetState();
}

class _AnimeCalendarWidgetState extends State<AnimeCalendarWidget> {
  late Future<SearchResult> _seasonResult;
  void onClose() => Navigator.pop(context);

  @override
  void initState() {
    super.initState();
    _setFutures();
  }

  _setFutures([bool fromCache = true]) {
    _seasonResult = MalApi.getCurrentSeason(
      fields: ["my_list_status"],
      fromCache: fromCache,
      limit: 500,
    );
    DalApi.i.resetScheduleForMalIds();
  }

  @override
  Widget build(BuildContext context) {
    return CFutureBuilder<SearchResult>(
      future: _seasonResult,
      done: (e) => CFutureBuilder<Map<int, ScheduleData>>(
        future: DalApi.i.scheduleForMalIds,
        done: (f) => _buildScheduleTree(e.data, f.data),
        loadingChild: loading,
      ),
      loadingChild: loading,
    );
  }

  Widget get loading {
    return _scaffoldWrapper(
      CustomScrollWrapper(
        [
          SB.lh30,
          SliverWrapper(loadingCenter()),
        ],
      ),
      onClose: onClose,
      onRefesh: null,
    );
  }

  Widget _buildScheduleTree(SearchResult? result, Map<int, ScheduleData>? map) {
    Map<int, Node> nodes = HashMap.fromEntries(result?.data
            ?.where(_onlyWithStatus)
            .map((e) => e.content)
            .map((e) => MapEntry(e!.id!, e)) ??
        []);
    final schedulesList = map?.entries
            .where((e) => _onlyWithSchedule(e, nodes))
            .map((e) => _mapToScheduledNode(e, nodes))
            .toList() ??
        [];
    if (schedulesList.isNotEmpty) {
      schedulesList.add(_SchduledNode._currentDayNode());
    }
    schedulesList
        .sort((a, b) => a.scheduleData.timestamp! - b.scheduleData.timestamp!);
    final dayMap = <int, List<_SchduledNode>>{};
    for (final sch in schedulesList) {
      if (dayMap.containsKey(sch.dayofWeek)) {
        dayMap[sch.dayofWeek]!.add(sch);
      } else {
        dayMap[sch.dayofWeek] = [sch];
      }
    }
    return _buildCustomScrollView(dayMap);
  }

  bool _onlyWithStatus(BaseNode node) {
    if (node?.content?.myListStatus != null) {
      if (node.content!.myListStatus is MyAnimeListStatus) {
        final status = node.content?.myListStatus as MyAnimeListStatus?;
        if (status?.status == null) return false;
        return status!.status!.equals("watching") ||
            status.status!.equals("plan_to_watch");
      }
    }
    return false;
  }

  bool _onlyWithSchedule(MapEntry<int, ScheduleData> e, Map<int, Node> nodes) {
    return nodes.containsKey(e.key);
  }

  Widget _buildCustomScrollView(Map<int, List<_SchduledNode>> map) {
    if (map.isEmpty)
      return _scaffoldWrapper(
        CustomScrollView(
          slivers: [
            if (map.isEmpty)
              SliverWrapper(
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: title(S.current.No_Scheduled_Notificatons,
                      fontSize: 16.0),
                ),
              )
          ],
        ),
        onClose: () => onClose(),
        onRefesh: () {
          setState(() {
            _setFutures(false);
          });
        },
      );
    else
      return _scaffoldWrapper(
        _ScheduleCustomList(
          scheduleNodeData: map,
        ),
        onClose: () => onClose(),
        onRefesh: () {
          setState(() {
            _setFutures(false);
          });
        },
      );
  }

  Widget _scaffoldWrapper(
    Widget child, {
    VoidCallback? onClose,
    VoidCallback? onRefesh,
  }) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(S.current.AnimeCalendar),
        actions: _actions(
          onClose: onClose,
          onRefesh: onRefesh,
        ),
      ),
      body: child,
    );
  }

  _SchduledNode _mapToScheduledNode(
      MapEntry<int, ScheduleData> e, Map<int, Node> nodes) {
    final date = DateTime.fromMillisecondsSinceEpoch(e.value.timestamp! * 1000);
    return _SchduledNode(
      date.weekday,
      e.value,
      nodes[e.key]!,
    );
  }
}

List<Widget> _actions({
  VoidCallback? onClose,
  VoidCallback? onRefesh,
}) {
  return [
    IconButton(
      onPressed: onRefesh,
      icon: Icon(Icons.refresh),
    ),
    IconButton(
      onPressed: onClose,
      icon: Icon(Icons.close),
    )
  ];
}

class _ScheduleCustomList extends StatefulWidget {
  final Map<int, List<_SchduledNode>> scheduleNodeData;
  final Widget Function()? header;
  const _ScheduleCustomList({
    Key? key,
    required this.scheduleNodeData,
    this.header,
  }) : super(key: key);

  @override
  State<_ScheduleCustomList> createState() => __ScheduleCustomListState();
}

class __ScheduleCustomListState extends State<_ScheduleCustomList> {
  final _filters = [
    _Filter(displayText: S.current.Plan_To_Watch, value: 'plan_to_watch'),
    _Filter(displayText: S.current.Watching, value: 'watching'),
  ];

  List<String> get _selectedFilters =>
      _filters.where((e) => e.isApplied).map((e) => e.value).toList();

  static const _weekdaysMap = {
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday',
    7: 'sunday'
  };
  StreamListener<int> _streamListener = StreamListener<int>();

  List<_SchduledNode> _currentDayNodes(int weekIndex) {
    return _mapAtIndex(weekIndex).value.where(_filterScheduleNode).toList();
  }

  MapEntry<int, List<_SchduledNode>> _mapAtIndex(int weekIndex) {
    return widget.scheduleNodeData.entries.elementAt(weekIndex);
  }

  @override
  void initState() {
    super.initState();
    _setupCurrentDayUpdater();
  }

  void _setupCurrentDayUpdater() {
    Future.doWhile(() => Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _streamListener.controller
                .add(DateTime.now().millisecondsSinceEpoch ~/ 1000);
            return true;
          }
          return false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.scheduleNodeData;
    return CustomScrollWrapper([
      if (widget.header != null) ...[
        SB.lh30,
        widget.header!(),
      ],
      _buildFilterHeader,
      for (int index = 0; index < map.length; ++index) ..._weekChildren(index)
    ]);
  }

  List<Widget> _weekChildren(int weekIndex) {
    final mapEntry = _mapAtIndex(weekIndex);
    final hasCurrentNode = mapEntry.value.any((e) => e.currentDay);
    return [
      SliverWrapper(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: title(_weekdaysMap[mapEntry.key]!.capitalize()),
        ),
      ),
      if (hasCurrentNode)
        StreamBuilder<int>(
          stream: _streamListener.stream,
          builder: (context, snapshot) {
            _setLatestTimestamp(mapEntry, snapshot);
            return _listTiles(mapEntry, weekIndex);
          },
        )
      else
        _listTiles(mapEntry, weekIndex)
    ];
  }

  void _setLatestTimestamp(MapEntry<int, List<_SchduledNode>> mapEntry,
      AsyncSnapshot<int> snapshot) {
    mapEntry.value.where((e) => e.currentDay).forEach((e) {
      if (snapshot.hasData) e.scheduleData.timestamp = snapshot.data!;
    });
  }

  SliverListWrapper _listTiles(
      MapEntry<int, List<_SchduledNode>> mapEntry, int weekIndex) {
    return SliverListWrapper(
      mapEntry.value
          .where(_filterScheduleNode)
          .mapIndexed((i, n) => _buildAnimeListTile(i, n, weekIndex))
          .toList(),
    );
  }

  bool _filterScheduleNode(_SchduledNode e) {
    if (e.currentDay) return true;
    return _selectedFilters
        .contains((e.anime.myListStatus as MyAnimeListStatus).status);
  }

  Widget _buildAnimeListTile(int index, _SchduledNode node, int dayIndex) {
    if (node.currentDay) {
      final nextNode = _getNextClosestNode(node);
      return _buildCurrentDayTile(node, index, nextNode);
    }
    final timestamp = node.scheduleData.timestamp!;
    final epsWidget = Text('Ep ${node.scheduleData.episode ?? '?'} in');
    final dateTime = ShadowButton(
      onPressed: () => _showShowSnack(S.current.Show, node),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Text(_hourMinText(timestamp)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => gotoPage(
            context: context,
            newPage: ContentDetailedScreen(
              node: node.anime,
            )),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SB.w15,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarWidget(
                    height: 60,
                    width: 60,
                    url: node.anime.mainPicture!.large,
                  ),
                  SB.h10,
                  dateTime
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      title(
                        node.anime.title,
                        fontSize: 16.0,
                        align: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CountDownWidget(
                          timestamp: timestamp,
                          elevation: 0,
                          prefix: epsWidget,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget get _buildFilterHeader {
    return SliverWrapper(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        child: Row(
          children: _filters
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0),
                  child: _buildFilter(e),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Padding _buildFilter(_Filter filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: PlainButton(
        child: filter.isApplied
            ? iconAndText(Icons.close, filter.displayText)
            : title(filter.displayText, fontSize: 12),
        onPressed: () {
          if (mounted)
            setState(() {
              filter.isApplied = !filter.isApplied;
            });
        },
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: btnBorder(context),
      ),
    );
  }

  Widget _buildCurrentDayTile(
      _SchduledNode node, int index, _SchduledNode? nextNode) {
    return StreamBuilder<int>(
        stream: _streamListener.stream,
        builder: (context, snapshot) {
          node.scheduleData.timestamp =
              snapshot.data ?? node.scheduleData.timestamp;
          return Container(
            height: 50.0,
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Stack(
              children: [
                Center(
                  child: Divider(thickness: 2),
                ),
                Center(
                  child: ToolTipButton(
                    message: '',
                    onTap: () {
                      if (nextNode != null) {
                        _showShowSnack(S.current.NextShow, nextNode);
                      }
                    },
                    padding: EdgeInsets.zero,
                    child: _currentTime(node),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _showShowSnack(String message, _SchduledNode nextNode) {
    final timestamp = _timeStampText(nextNode.scheduleData.timestamp!);
    String nextShowMsg =
        '$message: ${nextNode.anime.title} at ${timestamp.join(' ')}';
    showSnackBar(Text(nextShowMsg));
  }

  Widget _currentTime(_SchduledNode node) {
    final texts = _timeStampText(node.scheduleData.timestamp!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
        child: RichText(
            text: TextSpan(children: [
          TextSpan(
            text: texts[0],
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
          TextSpan(
            text: ' (${texts[1]})',
            style: TextStyle(
              fontSize: 10.0,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(.7),
            ),
          ),
        ])),
      ),
    );
  }

  List<String> _timeStampText(int stamp) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
    String hourMinText = _hourMinText(stamp);
    String timezoneText =
        '${timestamp.timeZoneName} ${timestamp.timeZoneOffset.isNegative ? '-' : '+'}${timestamp.timeZoneOffset.inHours}:${timestamp.timeZoneOffset.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    return [hourMinText, timezoneText];
  }

  String _hourMinText(int stamp) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  _SchduledNode? _getNextClosestNode(_SchduledNode node) {
    var list = widget.scheduleNodeData.values.flattened.where(_filterScheduleNode).toList();
    list.sort((a, b) => a.scheduleData.timestamp! - b.scheduleData.timestamp!);
    final index = list.indexOf(node);
    return list.tryAt(index + 1);
  }
}
