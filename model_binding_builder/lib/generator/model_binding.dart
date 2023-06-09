import 'package:analyzer/dart/element/type.dart';
import 'package:map_model_builder/src/base_generator.dart';
import 'package:map_model_builder/src/resolve_info.dart';
import 'package:model_binding/annotation/annotation.dart';

/// ModelBindingGenerator
class ModelBindingGenerator extends BaseGenerator<Binding> {
  /// mapClass
  @override
  String get mapClass => 'MapBinding';

  /// superClass
  @override
  String get superClass => 'ModelBinding';

  /// genExport
  @override
  String genExport(String exportString, Set<PropertyInfo> propertySet,
      Set<ConvertInfo> convertSet) {
    String include = '';
    for (var propertyInfo in propertySet) {
      if (include.isNotEmpty) {
        include += ',';
      }
      include += "'${propertyInfo.propertyName}'";
    }

    if (include.isNotEmpty) {
      include = 'includes: {$include},';
    }
    if (exportString.isNotEmpty) {
      return '''
      @override
      Map<String, dynamic> \$export() {
        var map = super.\$export();
        \$data.export($include target: map);
        return map;
      }
      ''';
    }
    return '';
  }

  @override
  String? customConvert(PropertyInfo propertyInfo) {
    var name = propertyInfo.propertyName;
    var type = propertyInfo.propertyType;
    if (type.isDartCoreList && type is ParameterizedType) {
      var propertyType = type.typeArguments.first;
      if (propertyType is InterfaceType) {
        var code = _convertType('e', propertyType);
        if (code != null) {
          return '$name.map((e) => $code).toList()';
        }
      }
    } else if (type.isDartCoreMap && type is ParameterizedType) {
      var keyType = type.typeArguments.first;
      var valueType = type.typeArguments.last;
      var keyCode = null;
      if (keyType is InterfaceType) {
        keyCode = _convertType('key', keyType);
      }
      var valueCode = null;
      if (valueType is InterfaceType) {
        valueCode = _convertType('value', valueType);
      }
      if (keyCode != null || valueCode != null) {
        return '$name.map((key, value) => MapEntry(${keyCode ?? 'key'}, ${valueCode ?? 'value'}))';
      }
    } else if (type is InterfaceType) {
      return _convertType(name, type);
    }

    return null;
  }

  String? _convertType(String name, InterfaceType propertyType) {
    var propertyTypeName =
        propertyType.getDisplayString(withNullability: false);
    if (!propertyType.isDartCoreString &&
        !propertyType.isDartCoreDouble &&
        !propertyType.isDartCoreInt &&
        !propertyType.isDartCoreBool) {
      return '$propertyTypeName($name)';
    }
    return null;
  }
}
