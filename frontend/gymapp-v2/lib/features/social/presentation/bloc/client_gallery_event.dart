import 'package:equatable/equatable.dart';

abstract class ClientGalleryEvent extends Equatable {
  const ClientGalleryEvent();

  @override
  List<Object?> get props => [];
}

class LoadClientGallery extends ClientGalleryEvent {}

class AddToClientGallery extends ClientGalleryEvent {
  final String filePath;
  final String fileName;

  const AddToClientGallery({required this.filePath, required this.fileName});

  @override
  List<Object?> get props => [filePath, fileName];
}

class DeleteFromClientGallery extends ClientGalleryEvent {
  final int itemId;

  const DeleteFromClientGallery(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
