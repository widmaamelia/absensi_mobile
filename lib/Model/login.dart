class LoginModel {
    bool success;
    String token;
    User user;

    LoginModel({
        required this.success,
        required this.token,
        required this.user,
    });

}

class User {
    int id;
    String name;
    String email;
    String role;
    String nomorInduk;
    String instansi;
    int mentorId;

    User({
        required this.id,
        required this.name,
        required this.email,
        required this.role,
        required this.nomorInduk,
        required this.instansi,
        required this.mentorId,
    });

}
