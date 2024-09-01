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
        text: S.current.Default_tab_selected_for_manga,
        desc: S.current.If_nothing_is_selected,
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
        text: S.current.Default_tab_selected_for_anime,
        desc: S.current.If_nothing_is_selected,
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
        text: S.current.Default_tab_selected_for_anime_manga,
        desc: S.current.If_nothing_is_selected,
        iconData: Icons.line_style,
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
      text: S.current.Custom_view_for_anime,
      desc: S.current.Custom_view_for_anime_desc,
      multiLine: true,
      child: SizedBox(
        height: 300.0,
        child: ContentCustomizer(),
      ),
    );
  }
}
