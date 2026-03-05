class Roles {
  static const double superadmin = 0;
  static const double operator = 0.5;
  static const double accountant = 1;
  static const double messengerAccountant = 1.5;
  static const double paymentUser = 2;
  static const double provider = 3;
}

final Map<double, List<String>> roleRoutes = {
  Roles.superadmin: ['*'],
  Roles.operator: ['/clients', '/client', '/services', '/sectors', '/onus'],
  Roles.accountant: ['/clients', '/client', '/payments'],
  Roles.messengerAccountant: ['/clients', '/client', '/payments', '/messenger'],
  Roles.provider: ['/home', '/clients', '/client', '/payments'],
  Roles.paymentUser: ['/clients', '/client'],
};
