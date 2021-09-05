import 'dart:math' as math;
import 'dart:ui';

import 'package:gtk/gtk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:appimagepool/screens/screens.dart';
import 'package:appimagepool/widgets/widgets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:appimagepool/utils/utils.dart';
import 'package:appimagepool/models/models.dart';

class BrowseView extends StatefulHookWidget {
  final BuildContext context;
  final ValueNotifier<bool> toggleSearch;
  final ValueNotifier<String> searchedTerm;
  final void Function(bool? value) switchSearchBar;
  final VoidCallback getData;
  final bool isConnected;
  final Map? categories;
  final Map? featured;
  final List? allItems;

  const BrowseView({
    Key? key,
    required this.context,
    required this.toggleSearch,
    required this.searchedTerm,
    required this.switchSearchBar,
    required this.getData,
    required this.isConnected,
    required this.categories,
    required this.featured,
    required this.allItems,
  }) : super(key: key);

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> with AutomaticKeepAliveClientMixin {
  final _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showCarouselArrows = useState<bool>(false);
    final carouselIndex = useState<int>(0);
    final navrailIndex = useState<int>(0);
    var itemsNew = widget.allItems != null && navrailIndex.value == 0
        ? widget.allItems!
            .where((element) => element['name'].toLowerCase().contains(widget.searchedTerm.value.toLowerCase(), 0))
            .toList()
        : widget.allItems != null && navrailIndex.value > 0 && widget.categories != null
            ? (widget.categories!.entries.toList()[navrailIndex.value - 1].value as List)
                .where((element) => element['name'].toLowerCase().contains(widget.searchedTerm.value.toLowerCase(), 0))
                .toList()
            : [];
    return !widget.isConnected
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AdwaitaIcon(AdwaitaIcons.network_no_route, size: 45),
              const SizedBox(height: 20),
              Text("Can't connect", style: context.textTheme.headline5),
              const SizedBox(height: 12),
              Text("You need an internet connection to use $appName.", style: context.textTheme.headline6),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: widget.getData, child: const Text('Retry')),
            ],
          )
        : widget.categories == null && widget.featured == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeBounce(color: context.textTheme.bodyText1!.color),
                  const SizedBox(height: 20),
                  Text("Fetching Softwares", style: context.textTheme.headline5),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (context.width >= mobileWidth)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: GtkSidebar(
                        padding: EdgeInsets.zero,
                        currentIndex: navrailIndex.value,
                        onSelected: (index) => navrailIndex.value = index,
                        children: [
                          GtkSidebarItem(
                            label: "Explore",
                            leading: const AdwaitaIcon(
                              AdwaitaIcons.explore2,
                              size: 17,
                            ),
                          ),
                          for (var category in widget.categories!.entries.toList().asMap().entries)
                            GtkSidebarItem(
                              label: category.value.key,
                              leading: AdwaitaIcon(
                                categoryIcons.containsKey(category.value.key)
                                    ? categoryIcons[category.value.key]!
                                    : AdwaitaIcons.question,
                                size: 19,
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (widget.toggleSearch.value)
                          Container(
                            color: getAdaptiveGtkColor(
                              context,
                              colorType: GtkColorType.headerBarBackgroundBottom,
                            ),
                            child: Center(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 260),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: 450,
                                    maxHeight: widget.toggleSearch.value ? 52 : 0,
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: RawKeyboardListener(
                                    child: TextField(
                                      textAlignVertical: TextAlignVertical.center,
                                      autofocus: true,
                                      onChanged: (query) {
                                        widget.searchedTerm.value = query;
                                      },
                                      style: context.textTheme.bodyText1!.copyWith(fontSize: 14),
                                      decoration: InputDecoration(
                                        fillColor: context.theme.canvasColor,
                                        contentPadding: const EdgeInsets.only(top: 8),
                                        isCollapsed: true,
                                        filled: true,
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    focusNode: FocusNode(),
                                    onKey: (event) {
                                      if (event.runtimeType == RawKeyDownEvent &&
                                          event.logicalKey.keyId == 4294967323) {
                                        widget.switchSearchBar(false);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: widget.searchedTerm.value.trim().isEmpty && navrailIndex.value == 0
                              ? SingleChildScrollView(
                                  controller: ScrollController(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Text(
                                          "Featured Apps",
                                          style: context.textTheme.headline6!
                                              .copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
                                        ),
                                      ),
                                      MouseRegion(
                                        onExit: (value) => showCarouselArrows.value = false,
                                        onHover: (value) => showCarouselArrows.value = true,
                                        child: Stack(
                                          children: [
                                            CarouselSlider.builder(
                                              itemCount: widget.featured!.length,
                                              itemBuilder: (context, index, i) {
                                                App featuredApp = App.fromItem(widget.featured!.values.toList()[index]);
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: GestureDetector(
                                                    onTap: () => Navigator.of(context).push(
                                                        MaterialPageRoute(builder: (ctx) => AppPage(app: featuredApp))),
                                                    child: Stack(
                                                      children: [
                                                        if (featuredApp.screenshotsUrl != null)
                                                          Container(
                                                              constraints: const BoxConstraints.expand(),
                                                              child: CachedNetworkImage(
                                                                imageUrl:
                                                                    featuredApp.screenshotsUrl![0].startsWith('http')
                                                                        ? (featuredApp.screenshotsUrl!)[0]
                                                                        : prefixUrl + featuredApp.screenshotsUrl![0],
                                                                fit: BoxFit.cover,
                                                              )),
                                                        Center(
                                                          child: Container(
                                                            color: context.isDark
                                                                ? Colors.grey.shade900.withOpacity(0.5)
                                                                : Colors.grey.shade300.withOpacity(0.5),
                                                            height: 400,
                                                            child: ClipRect(
                                                              child: BackdropFilter(
                                                                filter: ImageFilter.blur(
                                                                  sigmaX: 10,
                                                                  sigmaY: 10,
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 100,
                                                                      child: featuredApp.iconUrl != null
                                                                          ? featuredApp.iconUrl!.endsWith('.svg')
                                                                              ? SvgPicture.network(
                                                                                  featuredApp.iconUrl!,
                                                                                )
                                                                              : CachedNetworkImage(
                                                                                  imageUrl: featuredApp.iconUrl!,
                                                                                  fit: BoxFit.cover,
                                                                                  placeholder: (c, u) => const Center(
                                                                                    child: CircularProgressIndicator(),
                                                                                  ),
                                                                                  errorWidget: (c, w, i) =>
                                                                                      brokenImageWidget,
                                                                                )
                                                                          : brokenImageWidget,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        featuredApp.name,
                                                                        overflow: TextOverflow.ellipsis,
                                                                        style: context.textTheme.headline3,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              carouselController: _controller,
                                              options: CarouselOptions(
                                                  height: 400,
                                                  viewportFraction: 0.75,
                                                  initialPage: 0,
                                                  enableInfiniteScroll: true,
                                                  reverse: false,
                                                  autoPlay: true,
                                                  autoPlayInterval: const Duration(seconds: 3),
                                                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                                  autoPlayCurve: Curves.fastOutSlowIn,
                                                  enlargeCenterPage: true,
                                                  scrollDirection: Axis.horizontal,
                                                  onPageChanged: (idx, rsn) => carouselIndex.value = idx),
                                            ),
                                            if (showCarouselArrows.value) ...[
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: SizedBox(
                                                  height: 400,
                                                  child: CarouselArrow(
                                                    icon: AdwaitaIcons.go_previous,
                                                    onPressed: () => _controller.previousPage(),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: SizedBox(
                                                  height: 400,
                                                  child: CarouselArrow(
                                                    icon: AdwaitaIcons.go_next,
                                                    onPressed: () => _controller.nextPage(),
                                                  ),
                                                ),
                                              )
                                            ]
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(widget.featured!.length, (index) {
                                          return GestureDetector(
                                            onTap: () => _controller.animateToPage(index),
                                            child: Container(
                                              width: 10.0,
                                              height: 10.0,
                                              padding: const EdgeInsets.all(4),
                                              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: carouselIndex.value == index
                                                    ? (context.isDark ? Colors.white : Colors.black).withOpacity(0.9)
                                                    : (context.isDark ? Colors.white : Colors.black).withOpacity(0.4),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 20),
                                      if (widget.categories != null)
                                        Center(
                                          child: Container(
                                            constraints: BoxConstraints(
                                                maxWidth: math.min(
                                                    1200,
                                                    context.width >= mobileWidth
                                                        ? context.width - 300
                                                        : context.width)),
                                            child: Column(children: [
                                              for (var category in widget.categories!.entries.toList()) ...[
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        category.key,
                                                        style: context.textTheme.headline6!
                                                            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
                                                      ),
                                                      OutlinedButton.icon(
                                                        style: OutlinedButton.styleFrom(
                                                          primary: context.isDark ? Colors.grey[200] : Colors.grey[800],
                                                        ),
                                                        onPressed: () {
                                                          navrailIndex.value =
                                                              widget.categories!.keys.toList().indexOf(category.key) +
                                                                  1;
                                                        },
                                                        label: const Icon(Icons.chevron_right, size: 14),
                                                        icon: const Text("See all"),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                GridOfApps(
                                                  itemList: category.value.take(8).toList(),
                                                ),
                                              ],
                                            ]),
                                          ),
                                        )
                                    ],
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth: math.min(
                                            1400, context.width >= mobileWidth ? context.width - 300 : context.width)),
                                    child: GridOfApps(
                                        itemList: widget.searchedTerm.value.isEmpty && widget.categories != null
                                            ? widget.categories!.entries.toList()[navrailIndex.value - 1].value
                                            : itemsNew),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
  }

  @override
  bool get wantKeepAlive => true;
}