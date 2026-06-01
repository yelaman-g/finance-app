enum Scope {
  personal,
  family;

  String get query => this == Scope.family ? 'FAMILY' : 'PERSONAL';
}
