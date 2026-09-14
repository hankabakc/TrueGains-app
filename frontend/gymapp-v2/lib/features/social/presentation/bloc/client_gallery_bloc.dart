import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/client_gallery_repository.dart';
import '../../data/services/file_api_service.dart';
import 'client_gallery_event.dart';
import 'client_gallery_state.dart';

class ClientGalleryBloc extends Bloc<ClientGalleryEvent, ClientGalleryState> {
  final ClientGalleryRepository _repository;
  final FileApiService _fileApiService;

  ClientGalleryBloc(this._repository, this._fileApiService)
      : super(ClientGalleryInitial()) {
    on<LoadClientGallery>(_onLoadGallery);
    on<AddToClientGallery>(_onAddToGallery);
    on<DeleteFromClientGallery>(_onDeleteFromGallery);
  }

  Future<void> _onLoadGallery(
    LoadClientGallery event,
    Emitter<ClientGalleryState> emit,
  ) async {
    emit(ClientGalleryLoading());
    final result = await _repository.getMyGallery();
    if (result.success && result.data != null) {
      emit(ClientGalleryLoaded(result.data!));
    } else {
      emit(ClientGalleryError(result.message));
    }
  }

  Future<void> _onAddToGallery(
    AddToClientGallery event,
    Emitter<ClientGalleryState> emit,
  ) async {
    emit(ClientGalleryOperationLoading());
    
    final uploadResult = await _fileApiService.uploadFile(event.filePath, event.fileName);
    
    if (uploadResult.success && uploadResult.data != null) {
      final imageUrl = uploadResult.data!['url'];
      if (imageUrl == null) {
        emit(const ClientGalleryError('Dosya yükleme hatası: URL alınamadı.'));
        return;
      }
      final result = await _repository.addToGallery(imageUrl);
      
      if (result.success) {
        emit(const ClientGalleryOperationSuccess('Görsel başarıyla eklendi.'));
        add(LoadClientGallery());
      } else {
        emit(ClientGalleryError(result.message));
      }
    } else {
      emit(ClientGalleryError(uploadResult.message));
    }
  }

  Future<void> _onDeleteFromGallery(
    DeleteFromClientGallery event,
    Emitter<ClientGalleryState> emit,
  ) async {
    emit(ClientGalleryOperationLoading());
    final result = await _repository.deleteGalleryItem(event.itemId);
    if (result.success) {
      emit(const ClientGalleryOperationSuccess('Görsel başarıyla silindi.'));
      add(LoadClientGallery());
    } else {
      emit(ClientGalleryError(result.message));
    }
  }
}
