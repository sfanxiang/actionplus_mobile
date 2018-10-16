import 'body_part.dart';

class Human {
  Map<BodyPartIndex, BodyPart> _bodyParts;

  Map<BodyPartIndex, BodyPart> get bodyParts => _bodyParts;

  Human(Iterable<BodyPart> parts) {
    _bodyParts = new Map.fromIterable(parts,
        key: (item) => (item as BodyPart).partIndex, value: (item) => item);
  }

  @override
  String toString() {
    return (_bodyParts.values.toList()
          ..sort((a, b) => a.partIndex.index - b.partIndex.index))
        .map((item) => item.toString())
        .reduce((value, elem) {
      return value + '; ' + elem;
    });
  }
}
