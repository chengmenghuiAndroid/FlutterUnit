import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_unit/app/res/toly_icon.dart';
import 'package:flutter_unit/app/router/unit_router.dart';
import 'package:flutter_unit/components/permanent/circle.dart';
import 'package:flutter_unit/components/permanent/multi_chip_filter.dart';
import 'package:flutter_unit/components/project/default/empty_shower.dart';
import 'package:flutter_unit/components/project/default/loading_shower.dart';
import 'package:flutter_unit/components/project/items/widget/home_item_support.dart';
import 'package:flutter_unit/components/project/items/widget/techno_widget_list_item.dart';
import 'package:flutter_unit/widget_system/blocs/widget_system_bloc.dart';
import 'package:widget_repository/widget_repository.dart';
import 'package:db_storage/db_storage.dart';
import 'app_search_bar.dart';
import 'empty_search_page.dart';
import 'error_page.dart';

// SearchPage 可以复用 WidgetsBloc，进行局部的 Bloc
// 不必单独提供 SearchBloc 增加复杂性
class SearchPageProvider extends StatelessWidget {
  const SearchPageProvider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (BuildContext context) => WidgetsBloc(
        repository: BlocProvider.of<WidgetsBloc>(context).repository,
      ),
      child: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildStarFilter()),
          BlocBuilder<WidgetsBloc, WidgetsState>(builder: _buildBodyByState)
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return const SliverAppBar(
            pinned: true,
            title: AppSearchBar(),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 15.0),
                child: Icon(TolyIcon.icon_sound),
              )
            ],
          );
  }

  Widget _buildStarFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20, bottom: 5),
            child: Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Circle(
                  radius: 5,
                  color: Colors.orange,
                ),
                Text(
                  '星级查询',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          MultiChipFilter<int>(
            data: const [1, 2, 3, 4, 5],
            avatarBuilder: (_, index) =>
                CircleAvatar(child: Text((index + 1).toString())),
            labelBuilder: (_, selected) => Icon(
              Icons.star,
              color: selected ? Colors.blue : Colors.grey,
              size: 18,
            ),
            onChange: _doSelectStart,
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          )
        ],
      );

  Widget _buildBodyByState(BuildContext context, WidgetsState state) {
    Widget noSearchArg = const SliverToBoxAdapter(child: NotSearchPage());
    if (state.filter.name.isEmpty) {
      return noSearchArg;
    }

    if (state is WidgetsLoading) {
      return const SliverToBoxAdapter(child: LoadingShower());
    }

    if (state is WidgetsLoadFailed) {
      return const SliverToBoxAdapter(child: ErrorPage());
    }

    if (state is WidgetsLoaded) {
      if (state.widgets.isEmpty) {
        return const SliverToBoxAdapter(
          child: EmptyShower(
            message: "没数据，哥也没办法\n(≡ _ ≡)/~┴┴",
          ),
        );
      }
      return _buildSliverList(state.widgets);
    }
    return const SliverToBoxAdapter(child: NotSearchPage());
  }

  Widget _buildSliverList(List<WidgetModel> models) => SliverList(
        delegate: SliverChildBuilderDelegate(
            (_, int index) => Padding(
                padding: const EdgeInsets.only(
                    bottom: 10, top: 2, left: 10, right: 10),
                child: InkWell(
                    customBorder: HomeItemSupport.shapeBorderMap[index],
                    onTap: () => _toDetailPage(models[index]),
                    child: TechnoWidgetListItem(
                      data: models[index],
                    ))),
            childCount: models.length),
      );

  void _doSelectStart(List<int> select) {
    List<int> temp = select.map((e) => e + 1).toList();
    if (temp.length < 5) {
      temp.addAll(List.generate(5 - temp.length, (e) => -1));
    }
    WidgetsBloc widgetsBloc = BlocProvider.of<WidgetsBloc>(context);
    final WidgetFilter filter = widgetsBloc.state.filter.copyWith(
      stars: temp,
    );
    widgetsBloc.add(
      EventSearchWidget(filter: filter),
    );
  }

  void _toDetailPage(WidgetModel model) {
    //收起键盘
    final FocusScopeNode focusScope = FocusScope.of(context);
    if (focusScope.hasFocus) {
      focusScope.unfocus();
    }
    BlocProvider.of<WidgetDetailBloc>(context).add(FetchWidgetDetail(model));
    Navigator.pushNamed(context, UnitRouter.widget_detail,arguments: model);
  }
}

