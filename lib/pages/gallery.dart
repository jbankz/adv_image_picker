import 'dart:async';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:adv_image_picker/models/album_item.dart';
import 'package:adv_image_picker/models/result_item.dart';
import 'package:adv_image_picker/plugins/adv_image_picker_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_list/image_list.dart';

class GalleryPage extends StatefulWidget {
  final bool allowMultiple;
  final int? maxSize;

  GalleryPage({bool? allowMultiple, this.maxSize})
      : assert(maxSize == null || maxSize >= 0),
        this.allowMultiple = allowMultiple ?? true;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Album>? albums;
  List<int> rows = [];
  List<String> needToBeRendered = [];
  Album? _selectedAlbum;
  double _marginBottom = 0.0;
  String lastScroll = "";
  int batchCounter = 0;
  ImageListController? _controller;
  bool _multipleMode = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ValueNotifier<int> buttonController = ValueNotifier<int>(0);

  Future<void> getAlbums() async {
    try {
      List<Album> _albums = [];

      _albums = await AdvImagePickerPlugin.getAlbums();

      for (Album album in _albums) {
        var res = await AdvImagePickerPlugin.getAlbumAssetsId(album);
        album.items.addAll(res.map<AlbumItem>((id) {
          return AlbumItem(id);
        }));
      }

      this.albums = _albums.map((Album album) {
        return album.copyWith(assetCount: album.items.length);
      }).toList();
    } on PlatformException catch (e) {
      ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      if (scaffoldMessenger.mounted)
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text(e.message ?? '')));
    }
  }

  void _toggleMultipleMode() {
    // if (_controller == null || albums == null) return;
    if (!_multipleMode) {
      switchMultipleMode();
    } else {
      Navigator.pop(context);
    }
  }

  submit() async {
    List<ResultItem> images = [];

    List<ImageData>? imageData = await _controller!.getSelectedImage();

    if (imageData != null) {
      for (ImageData data in imageData) {
        images.add(ResultItem(data.albumId, data.assetId));
      }
    }
    // Widget page = ResultPage(images);

    // Navigator.push(
    //     context, MaterialPageRoute(builder: (BuildContext context) => page));

    Navigator.popUntil(context, ModalRoute.withName("AdvImagePickerHome"));
    if (Navigator.canPop(context)) Navigator.pop(context, images);
  }

  void switchMultipleMode() {
    buttonController.value = 0;
    _marginBottom = _multipleMode ? 0.0 : 80.0;
    _multipleMode = !_multipleMode;
    _controller!.setMaxImage(_multipleMode ? widget.maxSize : 1);
  }

  @override
  void initState() {
    super.initState();
  }

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
          backgroundColor: AdvImagePicker.primaryColor,
          child: Icon(
            CupertinoIcons.check_mark,
            size: 50,
          ),
          onPressed: () async {
            await submit();
          }),
      appBar: new AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          PopupMenuButton(
              onSelected: (int index) {
                setState(() {
                  _index = index;
                  _selectedAlbum = albums!.firstWhere(
                      (Album album) => album.name == albums![index].name);
                  _controller!.reloadAlbum(_selectedAlbum!.identifier);
                });
              },
              itemBuilder: (context) => List.generate(
                  albums!.length,
                  (index) => PopupMenuItem(
                        child: Text(albums![index].name),
                        value: index,
                      )))
        ],
        title: Center(
          child: Text(
            AdvImagePicker.gallery,
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loadAll(context),
        builder: (BuildContext context, _) => _buildWidget(context),
      ),
    );
  }

  Widget _buildWidget(BuildContext context) {
    if (albums == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedAlbum == null) return Container();

    return ImageList(
      fileNamePrefix: "asdfasdfasdf",
      albumId: _selectedAlbum!.identifier,
      maxImages: _multipleMode ? widget.maxSize : 1,
      onListCreated: _onListCreated,
      onImageTapped: _onImageTapped,
    );
  }

  Future<bool> _loadAll(BuildContext context) async {
    if (albums != null) return false;

    await getAlbums();
    _selectedAlbum = albums != null && albums!.length > 0 ? albums![0] : null;

    _toggleMultipleMode();

    setState(() {});

    return true;
  }

  void _onListCreated(ImageListController controller) {
    _controller = controller;
  }

  void _onImageTapped(int count) {
    if (!_multipleMode) {
      submit();
      return;
    }

    setState(() {
      buttonController.value = count;
    });
  }
}
