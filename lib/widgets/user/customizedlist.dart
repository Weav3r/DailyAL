import 'dart:collection';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dailyanimelist/api/dalapi.dart';
import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/pages/animedetailed/synopsiswidget.dart';
import 'package:dailyanimelist/pages/settings/notifsettings.dart';
import 'package:dailyanimelist/pages/settings/optiontile.dart';
import 'package:dailyanimelist/user/list_pref.dart';
import 'package:dailyanimelist/widgets/avatarwidget.dart';
import 'package:dailyanimelist/widgets/common/image_preview.dart';
import 'package:dailyanimelist/widgets/custombutton.dart';
import 'package:dailyanimelist/widgets/customfuture.dart';
import 'package:dailyanimelist/widgets/headerwidget.dart';
import 'package:dailyanimelist/widgets/home/animecard.dart';
import 'package:dailyanimelist/widgets/user/contentlistwidget.dart';
import 'package:dal_commons/commons.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
    var customizedLists =
        user.pref.animeMangaPagePreferences.contentCardProps ?? [];
    return ListView(
      children: [
        _addItemButton(),
        for (var item in customizedLists) _customizableFieldWidget(item),
      ],
    );
  }

  Padding _addItemButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ShadowButton(
        onPressed: () => _showUpdateDialog(false),
        child: Text(
          S.current.Add_an_Item,
        ),
      ),
    );
  }

  void _showUpdateDialog(
    bool editMode, [
    ContentCardProps? props,
  ]) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog.adaptive(
              title: Text(editMode
                  ? S.current.Edit_Display_Profile
                  : S.current.Add_display_profile),
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              insetPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 25),
              content: CustomizableFieldWidget(
                editMode: true,
                onUpdated: (value) {
                  if (editMode) {
                    user.pref.animeMangaPagePreferences.contentCardProps
                        ?.remove(props);
                  }
                  _setNewDisplayProfile(value);
                  user.setIntance();
                  if (mounted) {
                    setState(() {});
                  }
                },
                props: props ?? ContentCardProps.defaultObject(),
                node: BaseNode(content: _nodes.first),
              ),
              actions: [],
            ));
  }

  void _setNewDisplayProfile(ContentCardProps value) {
    logDal('Updated value: $value');
    if (user.pref.animeMangaPagePreferences.contentCardProps == null) {
      user.pref.animeMangaPagePreferences.contentCardProps = [value];
    } else {
      user.pref.animeMangaPagePreferences.contentCardProps!.add(value);
    }
  }

  Widget _customizableFieldWidget(ContentCardProps item) {
    return OptionTile(
      text: item.profileName,
      desc: S.current.Tap_to_edit,
      onPressed: () => _showUpdateDialog(true, item),
      trailing: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(S.current.Delete_Profile),
              content: Text(S.current.Are_you_sure_you_want_to_delete_profile),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.current.Cancel),
                ),
                TextButton(
                  onPressed: () {
                    user.pref.animeMangaPagePreferences.contentCardProps!
                        .remove(item);
                    user.setIntance();
                    Navigator.of(context).pop();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Text(S.current.Delete),
                ),
              ],
            ),
          );
        },
        icon: Icon(Icons.delete),
      ),
    );
  }
}

class CustomizableFieldWidget extends StatefulWidget {
  final BaseNode? node;
  final ContentCardProps props;
  final bool editMode;
  final ValueChanged<ContentCardProps>? onUpdated;
  const CustomizableFieldWidget({
    super.key,
    this.editMode = false,
    required this.props,
    this.node,
    this.onUpdated,
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
  final _formKey = GlobalKey<FormState>();
  late ContentCardProps props;

  @override
  void initState() {
    super.initState();
    props = widget.props;
    _fieldValues =
        Map.fromIterable(props.fields, key: (e) => e.type, value: (e) => e);
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
          ..._displayProfileName(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: _populateFields(),
          ),
          SB.h20,
          if (selectedField == null)
            Text(S.current.Tap_to_select,
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
          _actionButtons(),
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
              S.current.Drag_the_field,
              style: TextStyle(fontSize: 11),
            ),
            SB.h20,
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
                ShadowButton(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  onPressed: () => _moveToFront(),
                  child: Text(S.current.Move_to_front),
                ),
                ShadowButton(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  onPressed: () => _moveToBack(),
                  child: Text(S.current.Move_to_front),
                ),
              ],
            )
          ],
        ),
      ),
    ];
  }

  void _moveToFront() {
    final index = _fieldValues.keys.toList().indexOf(selectedField!);
    if (index != _fieldValues.length - 1) {
      final selectedFieldValue = _fieldValues[selectedField]!;
      final nextFieldKey = _fieldValues.keys.elementAt(index + 1);

      setState(() {
        _fieldValues.remove(selectedField);

        final newFieldValues =
            LinkedHashMap<CustomizableFieldType, CustomizableField>();
        _fieldValues.forEach((key, value) {
          newFieldValues[key] = value;
          if (key == nextFieldKey) {
            newFieldValues[selectedField!] = selectedFieldValue;
          }
        });

        _fieldValues
          ..clear()
          ..addAll(newFieldValues);
      });
    }
  }

  void _moveToBack() {
    final index = _fieldValues.keys.toList().indexOf(selectedField!);
    if (index != 0) {
      final selectedFieldValue = _fieldValues[selectedField]!;
      final previousFieldKey = _fieldValues.keys.elementAt(index - 1);

      setState(() {
        _fieldValues.remove(selectedField);

        final newFieldValues =
            LinkedHashMap<CustomizableFieldType, CustomizableField>();
        _fieldValues.forEach((key, value) {
          if (key == previousFieldKey) {
            newFieldValues[selectedField!] = selectedFieldValue;
          }
          newFieldValues[key] = value;
        });

        _fieldValues
          ..clear()
          ..addAll(newFieldValues);
      });
    }
  }

  SizedBox _populateFields() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: props.height,
      child: Stack(
        children: [
          for (final field in _fieldValues.values)
            if (!field.hidden)
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
                      '${S.current.Next_episode} ${data.episode} in ${timer.expanded()}');
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
        padding: EdgeInsets.symmetric(horizontal: 5),
        onPressed: widget.editMode
            ? () => _setSelected(CustomizableFieldType.edit_button)
            : () {
                showContentEditSheet(context, 'anime', node);
              },
        child: myListStatus == null
            ? Icon(Icons.edit)
            : AutoSizeText(
                s,
                minFontSize: 6,
                maxFontSize: 13,
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

  List<Widget> _displayProfileName() {
    return [
      Form(
        key: _formKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SB.w20,
            Text(
              S.current.Profile_name,
              style: TextStyle(fontSize: 12),
            ),
            SB.w20,
            Expanded(
              child: TextFormField(
                initialValue: props.profileName,
                onSaved: (newValue) =>
                    props = props.copyWith(profileName: newValue!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.current.Enter_valid_profile;
                  }
                  if (!_isAlphaNumeric(value)) {
                    return S.current.Should_be_aplhanumeric;
                  }
                  return null;
                },
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: S.current.Enter_profile_name,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SB.w20,
          ],
        ),
      ),
      SB.h20,
    ];
  }

  
  bool _isAlphaNumeric(String value) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SB.w20,
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            _formKey.currentState!.save();
            props = props.copyWith(
              id: Uuid().v4(),
              fields: _fieldValues.values.toList(),
            );
            widget.onUpdated?.call(props);
            Navigator.of(context).pop();
          },
          child: Text(S.current.Save),
        ),
        SB.w20,
        TextButton(
          onPressed: () {
            props = props.copyWith(fields: _fieldValues.values.toList());
            if (widget.props == props) {
              Navigator.of(context).pop();
            } else {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(S.current.Discard_changes),
                  content: Text(S.current.Are_you_sure_you_want_to_discard),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(S.current.Cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(S.current.Discard),
                    ),
                  ],
                ),
              );
            }
          },
          child: Text(S.current.Close),
        ),
        SB.w20,
      ],
    );
  }
}
