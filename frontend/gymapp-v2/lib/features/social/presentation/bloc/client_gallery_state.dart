import 'package:equatable/equatable.dart';
import '../../data/models/client_gallery_model.dart';

abstract class ClientGalleryState extends Equatable {
  const ClientGalleryState();

  @override
  List<Object?> get props => [];
}

class ClientGalleryInitial extends ClientGalleryState {}

class ClientGalleryLoading extends ClientGalleryState {}

class ClientGalleryLoaded extends ClientGalleryState {
  final List<ClientGalleryModel> images;

  const ClientGalleryLoaded(this.images);

  @override
  List<Object?> get props => [images];
}

class ClientGalleryError extends ClientGalleryState {
  final String message;

  const ClientGalleryError(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientGalleryOperationLoading extends ClientGalleryState {}

class ClientGalleryOperationSuccess extends ClientGalleryState {
  final String message;

  const ClientGalleryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
