import 'dart:convert';

import 'package:dailyanimelist/api/dalapi.dart';
import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/pages/animedetailed/synopsiswidget.dart';
import 'package:dailyanimelist/pages/settings/notifsettings.dart';
import 'package:dailyanimelist/widgets/avatarwidget.dart';
import 'package:dailyanimelist/widgets/common/image_preview.dart';
import 'package:dailyanimelist/widgets/custombutton.dart';
import 'package:dailyanimelist/widgets/customfuture.dart';
import 'package:dailyanimelist/widgets/headerwidget.dart';
import 'package:dailyanimelist/widgets/home/animecard.dart';
import 'package:dailyanimelist/widgets/user/contentlistwidget.dart';
import 'package:dal_commons/commons.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContentCardProps {
  final double height;
  final List<CustomizableField> fields;
  ContentCardProps({
    required this.height,
    required this.fields,
  });
}

class Position {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  Position({
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  Position copyWith({
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Position(
      top: top ?? this.top,
      left: left ?? this.left,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  String toString() {
    return 'Position(top: $top, left: $left, right: $right, bottom: $bottom)';
  }
}

enum CustomizableFieldType {
  title,
  image,
  media_type,
  mean_score,
  num_list_users,
  list_status,
  watched_episodes,
  list_score,
  edit_button,
  next_episode_counter,
  un_seen_episodes,
}

class CustomizableField {
  final CustomizableFieldType type;
  final String title;
  final String description;
  final Position position;

  CustomizableField({
    required this.type,
    required this.title,
    required this.description,
    required this.position,
  });

  CustomizableField copyWith({
    CustomizableFieldType? type,
    String? title,
    String? description,
    Position? position,
  }) {
    return CustomizableField(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
    );
  }

  @override
  String toString() {
    return 'CustomizableField(type: $type, title: $title, description: $description, position: $position)';
  }
}

String _imageUrl(value) {
  if (value is AnimeDetailed) {
    final content = value;
    return content.mainPicture?.large ?? content.mainPicture?.medium ?? '';
  }
  final content2 = value?.content;
  return content2?.mainPicture?.large ?? '';
}

class ContentCustomizer extends StatefulWidget {
  const ContentCustomizer({super.key});

  @override
  State<ContentCustomizer> createState() => _ContentCustomizerState();
}

class _ContentCustomizerState extends State<ContentCustomizer> {
  List<Node> _nodes = List.from(jsonDecode(sampleNodesList))
      .map((e) => AnimeDetailed.fromJson(e['node']))
      .toList();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _addItemButton(),
      ],
    );
  }

  Padding _addItemButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ShadowButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog.adaptive(
                    title: Text(S.current.Add_an_Item),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                    insetPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 25),
                    content: CustomizableFieldWidget(
                      props: ContentCardProps(
                          fields: _getDefaultFields(), height: 150),
                      node: BaseNode(content: _nodes.first),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(S.current.Close),
                      ),
                    ],
                  ));
        },
        child: Text(
          S.current.Add_an_Item,
        ),
      ),
    );
  }
}

List<CustomizableField> _getDefaultFields() {
  return [
    _titleField(),
    _imageField(),
    _mediaTypeField(),
    _scoreField(),
    _numListUsersField(),
    _listScoreField(),
    _editButtonField(),
    _countDownField(),
    _unSeenEpisodesField(),
  ];
}

CustomizableField _unSeenEpisodesField() {
  return CustomizableField(
    type: CustomizableFieldType.un_seen_episodes,
    title: 'Unseen Episodes',
    description: 'Number of unseen episodes',
    position: Position(
      bottom: 3.5,
      left: 60,
    ),
  );
}

CustomizableField _mediaTypeField() {
  return CustomizableField(
    type: CustomizableFieldType.media_type,
    title: 'Media Type',
    description: 'Type of the media',
    position: Position(
      top: 5,
      right: 25,
    ),
  );
}

CustomizableField _imageField() {
  return CustomizableField(
    type: CustomizableFieldType.image,
    title: 'Image',
    description: 'Image of the item',
    position: Position(
      top: 5,
      left: 5,
    ),
  );
}

CustomizableField _titleField() {
  return CustomizableField(
    type: CustomizableFieldType.title,
    title: 'Title',
    description: 'Title of the item',
    position: Position(
      top: 40,
      left: 100,
    ),
  );
}

CustomizableField _scoreField() {
  return CustomizableField(
    type: CustomizableFieldType.mean_score,
    title: 'Mean Score',
    description: 'Mean score of the item',
    position: Position(
      top: 5,
      left: 100,
    ),
  );
}

CustomizableField _numListUsersField() {
  return CustomizableField(
    type: CustomizableFieldType.num_list_users,
    title: 'Number of List Users',
    description: 'Number of users who have this item in their list',
    position: Position(
      top: 7,
      left: 150,
    ),
  );
}

CustomizableField _listScoreField() {
  return CustomizableField(
    type: CustomizableFieldType.list_score,
    title: 'List Score',
    description: 'Score given to the item',
    position: Position(
      bottom: 13,
      left: 100,
    ),
  );
}

CustomizableField _editButtonField() {
  return CustomizableField(
    type: CustomizableFieldType.edit_button,
    title: 'Edit Button',
    description: 'Button to edit the item',
    position: Position(
      bottom: 10,
      right: 10,
    ),
  );
}

CustomizableField _countDownField() {
  return CustomizableField(
    type: CustomizableFieldType.next_episode_counter,
    title: 'Next Episode Counter',
    description: 'Countdown to next episode',
    position: Position(
      bottom: 10,
      right: 100,
    ),
  );
}

class CustomizableFieldWidget extends StatefulWidget {
  final BaseNode? node;
  final ContentCardProps props;
  final bool editMode;
  const CustomizableFieldWidget({
    super.key,
    this.editMode = true,
    required this.props,
    this.node,
  });

  @override
  State<CustomizableFieldWidget> createState() =>
      _CustomizableFieldWidgetState();
}

class _CustomizableFieldWidgetState extends State<CustomizableFieldWidget> {
  CustomizableFieldType? selectedField;
  Map<CustomizableFieldType, CustomizableField> _fieldValues = {};
  List<String> get _fieldNames =>
      _fieldValues.values.map((e) => e.title).toList();

  @override
  void initState() {
    super.initState();
    _fieldValues = Map.fromIterable(widget.props.fields,
        key: (e) => e.type, value: (e) => e);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DalApi.i.onScheduleLoaded(() {
        logDal('Schedule loaded');
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  AnimeDetailed? get node => widget.node?.content as AnimeDetailed?;
  MyAnimeListStatus? get myListStatus =>
      (widget.node?.myListStatus ?? widget.node?.content?.myListStatus)
          as MyAnimeListStatus?;

  @override
  Widget build(BuildContext context) {
    if (!widget.editMode) {
      return _populateFields();
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SB.h20,
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: _populateFields(),
          ),
          SB.h20,
          if (selectedField == null)
            Text('Tap to select a field to edit',
                style: TextStyle(fontSize: 11)),
          SB.h10,
          HeaderWidget(
            width: MediaQuery.of(context).size.width,
            header: _fieldNames,
            fontSize: 13.0,
            applyTextColor: true,
            shouldAnimate: false,
            itemPadding: EdgeInsets.symmetric(horizontal: 5),
            selectedIndex: selectedField == null
                ? -1
                : _fieldNames.indexOf(_fieldValues[selectedField!]!.title),
            onPressed: (index) {
              var field = _fieldValues.values.elementAt(index);
              _setSelected(field.type);
            },
          ),
          if (selectedField != null) ..._onSelectedOptions,
          SB.h20,
        ],
      ),
    );
  }

  List<Widget> get _onSelectedOptions {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              'Drag the field or use arrow keys to move the field',
              style: TextStyle(fontSize: 11),
            ),
            SB.h20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _moveButton(_fieldValues[selectedField!]!, AxisDirection.up),
                _moveButton(_fieldValues[selectedField!]!, AxisDirection.left),
                _moveButton(_fieldValues[selectedField!]!, AxisDirection.right),
                _moveButton(_fieldValues[selectedField!]!, AxisDirection.down),
              ],
            ),
            SB.h10,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Deselect',
                  onPressed: () {
                    setState(() {
                      selectedField = null;
                    });
                  },
                  icon: Icon(Icons.deselect),
                ),
              ],
            )
          ],
        ),
      ),
    ];
  }

  SizedBox _populateFields() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: widget.props.height,
      child: Stack(
        children: [
          for (final field in _fieldValues.values)
            Positioned(
              top: field.position.top,
              left: field.position.left,
              right: field.position.right,
              bottom: field.position.bottom,
              child: _customizeField(field, buildField(field)),
            ),
        ],
      ),
    );
  }

  Widget _customizeField(CustomizableField field, Widget built) {
    if (!widget.editMode) {
      return built;
    }
    var isSelected = selectedField == field.type;
    var borderColor =
        isSelected ? Theme.of(context).dividerColor : Colors.transparent;
    return GestureDetector(
      onTap: () => _setSelected(field.type),
      onPanUpdate: (details) {
        var primaryDelta = details.delta;
        var x = primaryDelta.dx;
        var y = primaryDelta.dy;
        _updatePosition(field, y, x);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: built,
      ),
    );
  }

  void _updatePosition(CustomizableField field, double y, double x) {
    if (selectedField == field.type) {
      var pos = field.position;
      setState(() {
        field = field.copyWith(
          position: field.position.copyWith(
            top: pos.top == null ? null : (pos.top! + y),
            left: pos.left == null ? null : (pos.left! + x),
            right: pos.right == null ? null : (pos.right! - x),
            bottom: pos.bottom == null ? null : (pos.bottom! - y),
          ),
        );
        _fieldValues[field.type] = field;
      });
    }
  }

  Widget _moveButton(CustomizableField field, AxisDirection direction) {
    return IconButton.filledTonal(
      onPressed: () {
        double y;
        double x;
        if (direction == AxisDirection.up || direction == AxisDirection.down) {
          y = direction == AxisDirection.up ? -5 : 5;
          x = 0;
        } else {
          y = 0;
          x = direction == AxisDirection.left ? -5 : 5;
        }
        _updatePosition(field, y, x);
      },
      icon: switch (direction) {
        AxisDirection.up => Icon(Icons.arrow_upward),
        AxisDirection.down => Icon(Icons.arrow_downward),
        AxisDirection.left => Icon(Icons.arrow_back),
        AxisDirection.right => Icon(Icons.arrow_forward),
      },
    );
  }

  Widget buildField(CustomizableField field) {
    return switch (field.type) {
      CustomizableFieldType.title => _titleWidget(),
      CustomizableFieldType.image => _imageWidget(),
      CustomizableFieldType.media_type => _mediaTypeWidget(),
      CustomizableFieldType.mean_score =>
        starWwidget(node?.mean?.toString() ?? '-', EdgeInsets.zero),
      CustomizableFieldType.num_list_users => _listUserWidget(),
      CustomizableFieldType.list_score =>
        starWwidget(myListStatus?.score?.toString() ?? '-'),
      CustomizableFieldType.edit_button => _editButtonWidget(),
      CustomizableFieldType.next_episode_counter => _episodeCounterWidget(),
      CustomizableFieldType.un_seen_episodes => _unSeenEpisodesWidget(),
      _ => SB.z
    };
  }

  Widget _episodeCounterWidget() {
    final data = DalApi.i.scheduleForMalIdsSync[node!.id!];
    if (data?.timestamp == null) {
      return SB.z;
    }
    return SizedBox(
      height: 30.0,
      child: CountDownWidget(
        timestamp: data!.timestamp!,
        customTimer: (timer) => ShadowButton(
          padding: EdgeInsets.symmetric(horizontal: 15),
          onPressed: widget.editMode
              ? () => _setSelected(CustomizableFieldType.next_episode_counter)
              : () {
                  showToast(
                      'Next episode ${data.episode} in ${timer.expanded()}');
                },
          child: Text(
            timer.highestOnly(),
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  SizedBox _editButtonWidget() {
    NodeStatusValue nsv = NodeStatusValue.fromListStatus(myListStatus);
    final data = DalApi.i.scheduleForMalIdsSync[node!.id!];
    int? episodes;
    if (node?.numEpisodes == null || node!.numEpisodes == 0) {
      if (data?.episode != null) {
        episodes = data!.episode! - 1;
      }
    } else {
      episodes = node!.numEpisodes!;
    }
    var s = '${myListStatus?.numEpisodesWatched ?? '-'} / ${episodes ?? '-'}';
    return SizedBox(
      width: myListStatus == null ? 30.0 : 60.0,
      height: 30,
      child: ShadowButton(
        backgroundColor: nsv.color,
        padding: EdgeInsets.zero,
        onPressed: widget.editMode
            ? () => _setSelected(CustomizableFieldType.edit_button)
            : () {
                showContentEditSheet(context, 'anime', node);
              },
        child: myListStatus == null
            ? Icon(Icons.edit)
            : Text(
                s,
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  Widget _listUserWidget() {
    if (node?.numListUsers == null) {
      return SB.z;
    }
    return title(
      '(${userCountFormat.format(node!.numListUsers)})',
      fontSize: 9,
      opacity: .7,
    );
  }

  Text _mediaTypeWidget() {
    final content = node;
    return Text(
      (content?.mediaType ?? '').toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
      ),
    );
  }

  Widget _imageWidget() {
    final offset = 43.0;
    var imageUrl = _imageUrl(node);

    if (widget.editMode) {
      return Container(
        height: offset * 3,
        width: offset * 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return AvatarWidget(
      height: offset * 3,
      width: offset * 2,
      useUserImageOnError: false,
      radius: BorderRadius.circular(4),
      onTap: () => zoomInImage(context, imageUrl),
      onLongPress: () => zoomInImage(context, imageUrl),
      url: imageUrl,
      userRoundBorderforLoading: false,
    );
  }

  void _setSelected(CustomizableFieldType type) {
    setState(() {
      selectedField = type;
    });
  }

  SizedBox _titleWidget() {
    final nodeTitle = getNodeTitle(node);
    return SizedBox(
      width: 230.0,
      child: title(
        nodeTitle,
        textOverflow: TextOverflow.fade,
        fontSize: nodeTitle.length < 30 ? 14 : 13,
        scaleFactor: 1,
        opacity: 1,
      ),
    );
  }

  Widget _unSeenEpisodesWidget() {
    Widget? result;
    var content2 = widget.node?.content;
    if (content2 is AnimeDetailed && myListStatus?.numEpisodesWatched != null) {
      final alreadyAired = "finished_airing".equalsIgnoreCase(content2.status);
      var episodesWatched = myListStatus?.numEpisodesWatched as int;
      if (alreadyAired && content2.numEpisodes != null) {
        result = _episodeUnseenWidgets(content2.numEpisodes!, episodesWatched);
      } else {
        var data = DalApi.i.scheduleForMalIdsSync[content2.id!];
        if (data != null) {
          result = unseenUsingScheduleData(
            data: data,
            baseNode: widget.node,
            myListStatus: myListStatus,
            onBuild: _episodeUnseenWidgets,
          );
        }
      }
    }
    return result ?? SB.z;
  }

  Widget? _episodeUnseenWidgets(int episodesAired, int episodesWatched) {
    if (episodesAired <= episodesWatched) {
      return null;
    }
    var epsDifference = episodesAired - episodesWatched;
    return _episodePill(epsDifference, Colors.red[700]);
  }

  Container _episodePill(int epsDifference, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${NumberFormat.compact().format(epsDifference)}',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
    );
  }
}
