// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:ragnrock/services/settings_service.dart';
class LlmService extends GetxService {
  final SettingsService _settings = Get.find<SettingsService>();
  final status = LlamaStatus.uninitialized.obs;
  final llamaParent = Rxn<LlamaParent>();
  bool get isReady => status.value == LlamaStatus.ready;
  Future<void> reloadModel() async {
    print('[LLM] Reload requested...');
    await disposeModel();
    await initialize();
  }
  Future<void> initialize() async {
    if (_settings.modelPath.value.isEmpty) {
      print('[LLM] No model path set. Skipping initialization.');
      status.value = LlamaStatus.uninitialized;
      return;
    }
    if (status.value == LlamaStatus.loading) {
      print('[LLM] Initialization already in progress.');
      return;
    }
    print('[LLM] Starting background initialization...');
    status.value = LlamaStatus.loading;
    try {
      Llama.libraryPath = 'libmtmd.dylib';
      final contextParams = ContextParams()
        ..nPredict = -1
        ..nCtx = _settings.contextSize.value
        ..nThreads = _settings.cpuThreads.value
        ..nBatch = _settings.batchSize.value
        ..nUbatch = _settings.batchSize.value;
      final samplerParams = SamplerParams()
        ..temp = _settings.temperature.value
        ..topK = _settings.topK.value
        ..topP = _settings.topP.value
        ..penaltyRepeat = _settings.repeatPenalty.value;
      final modelParams = ModelParams()
        ..nGpuLayers = _settings.gpuLayers.value; 
      final load = LlamaLoad(
        path: _settings.modelPath.value, 
        modelParams: modelParams,
        contextParams: contextParams,
        samplingParams: samplerParams,
        mmprojPath: _settings.visionModelPath.value.isEmpty ? null : _settings.visionModelPath.value, 
      );
      final parent = LlamaParent(load);
      await parent.init();
      llamaParent.value = parent;
      while (parent.status != LlamaStatus.ready) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      status.value = LlamaStatus.ready;
      print('[LLM] Model ready!');
    } catch (e, st) {
      print('[LLM] Initialization error: $e\n$st');
      status.value = LlamaStatus.error;
      llamaParent.value = null;
    }
  }
  LlamaScope getScope() {
    if (!isReady || llamaParent.value == null) {
      throw StateError('LlamaService is not ready. Check status before calling getScope.');
    }
    return llamaParent.value!.getScope();
  }
  Future<void> disposeModel() async {
    if (llamaParent.value != null) {
      await llamaParent.value!.dispose();
      llamaParent.value = null;
      status.value = LlamaStatus.uninitialized;
      print('[LLM] Model disposed');
    }
  }
  @override
  void onInit() {
    print(">>> LlmService has been initialized");
    super.onInit();
  }
  @override
  void onClose() {
    print(">>> LlmService is being closed. Disposing model...");
    disposeModel();
    super.onClose();
  }
}