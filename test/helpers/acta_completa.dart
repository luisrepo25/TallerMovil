import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';

extension ActaCompletaParaPruebas on ActaLocal {
  /// Responde todo lo obligatorio para poder cerrarla: extintores, seguridad (sin fallas y
  /// rutas despejadas) y la confirmación de que no hay materiales combustibles.
  ActaLocal completa({int extintores = 1}) => copyWith(
    estadoExtintoresId: extintores,
    fallasElectricas: false,
    rutasDespejadas: true,
    sinMateriales: true,
  );
}
