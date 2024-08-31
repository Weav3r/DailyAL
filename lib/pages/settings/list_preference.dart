import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/enums.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/pages/settings/customsettings.dart';
import 'package:dailyanimelist/pages/settings/optiontile.dart';
import 'package:dailyanimelist/widgets/selectbottom.dart';
import 'package:dailyanimelist/widgets/user/customizedlist.dart';
import 'package:flutter/material.dart';

class ListPreferenceSettings extends StatefulWidget {
  const ListPreferenceSettings({super.key});

  @override
  State<ListPreferenceSettings> createState() => _ListPreferenceSettingsState();
}

class _ListPreferenceSettingsState extends State<ListPreferenceSettings> {
  @override
  Widget build(BuildContext context) {
    return SettingSliverScreen(
      titleString: S.current.List_preferences,
      child: SliverList.list(
        children: [
          _defaultTabSelected(),
          _defaultAnimeTabSelected(),
          _defaultMangaTabSelected(),
          _customViewForAnime(),
        ],
      ),
    );
  }

  Widget _defaultMangaTabSelected() {
    return OptionTile(
        text: 'Default tab selected for manga',
        desc: 'If nothing is selected, it will default to last opened one.',
        trailing: SelectButton(
          options: ['none', ...allMangaStatusMap.keys.toList()],
          displayValues: ['None', ...allMangaStatusMap.values.toList()],
          selectedOption:
              user.pref.animeMangaPagePreferences.defaultMangaTabSelected,
          onChanged: (newValue) {
            if (mounted)
              setState(() {
                user.pref.animeMangaPagePreferences.defaultMangaTab = newValue;
                user.setIntance();
              });
          },
        ),
        onPressed: null);
  }

  Widget _defaultAnimeTabSelected() {
    return OptionTile(
        text: 'Default tab selected for anime',
        desc: 'If nothing is selected, it will default to last opened one.',
        trailing: SelectButton(
          options: ['none', ...allAnimeStatusMap.keys.toList()],
          displayValues: ['None', ...allAnimeStatusMap.values.toList()],
          selectedOption:
              user.pref.animeMangaPagePreferences.defaultAnimeTabSelected,
          onChanged: (newValue) {
            if (mounted)
              setState(() {
                user.pref.animeMangaPagePreferences.defaultAnimeTab = newValue;
                user.setIntance();
              });
          },
        ),
        onPressed: null);
  }

  Widget _defaultTabSelected() {
    return OptionTile(
        text: 'Default tab selected for anime/manga',
        iconData: Icons.line_style,
        desc: 'If nothing is selected, it will default to last opened one.',
        trailing: SelectButton(
          options: ['none', 'anime', 'manga'],
          displayValues: ['None', 'Anime', 'Manga'],
          selectedOption:
              user.pref.animeMangaPagePreferences.defaultTabSelected,
          onChanged: (newValue) {
            if (mounted)
              setState(() {
                user.pref.animeMangaPagePreferences.defaultTab = newValue;
                user.setIntance();
              });
          },
        ),
        onPressed: null);
  }

  Widget _customViewForAnime() {
    return AccordionOptionTile(
      isOpen: true,
      text: 'Custom view for anime',
      desc: 'Customize the view for anime tab when list view is selected.',
      child: SizedBox(
        height: 300.0,
        child: ContentCustomizer(),
      ),
    );
  }
}
