import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locals/src/models/route_argument.dart';
import 'package:locals/src/utils/constants.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as repository;
import 'package:image_picker/image_picker.dart';
import '../pages/retrieve_code.dart';



class UserController extends ControllerMVC {
  User user = new User();
  bool loading = false;
  GlobalKey<FormState> loginFormKey;
  GlobalKey<FormState> registerFormKey;
  GlobalKey scaffoldKey ;
  bool passwordShow = true;
  bool maleCheck = false;
  String devicetokken;
  bool femaleCheck = false;
  bool businessCheck = false;
  int currentLoading = 0;
  String assignednumber="0";
  String accountnumber="";

  TextEditingController emailController;
  TextEditingController numberController=TextEditingController();

  TextEditingController passwordController;
  TextEditingController nameController;

  TextEditingController verificationCodeController;

  bool registerVerified = false;
  var registerVerificationCode ;
  var privacyPolicyData;
  var userAgreement;
  bool userAgreementDataLoaded = false;
  bool userPolicyDataLoaded = false;

  UserController() {
    // loader = Helper.overlayLoader(context);
    loginFormKey = new GlobalKey<FormState>();
    registerFormKey = new GlobalKey<FormState>();
    scaffoldKey = new GlobalKey();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    verificationCodeController = new TextEditingController();
    loading = false;
  }

  void showPassword() {
    setState(() {
      passwordShow = true;
    });
  }

  void hidePassword() {
    setState(() {
      passwordShow = false;
    });
  }

  void maleCheckHandle() {
    if(maleCheck) {
      setState(() {
        maleCheck = false;
      });
    } else {
      setState(() {
        maleCheck = true;
        femaleCheck = false;
        businessCheck = false;
      });
    }
  }

  void femaleCheckHandle() {
    if(femaleCheck) {
      setState(() {
        femaleCheck = false;
      });
    } else {
      setState(() {
        femaleCheck = true;
        maleCheck = false;
        businessCheck = false;
      });
    }
  }

  void businessCheckHandle() {
    if(businessCheck) {
      setState(() {
        businessCheck = false;
      });
    } else {
      setState(() {
        businessCheck = true;
        femaleCheck = false;
        maleCheck = false;
      });
    }
  }

  login() async {

    FirebaseMessaging.instance.getToken().then((value) {
      devicetokken = value;

      log("------token" + devicetokken);
    });
    setState((){loading = true;});
    try{
      String response =await repository.userLogin(accountnumber, passwordController.text);
      final jsonResponse = json.decode(response);
      Constants.userresponse = jsonResponse;
      if(jsonResponse['success'] == true){
      log(jsonResponse['user']['_id']);
      log(devicetokken);

        final sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString('_id', jsonResponse['user']['_id']);
        sharedPreferences.setString('name', jsonResponse['user']['name']);
        sharedPreferences.setString('email', jsonResponse['user']['number']);
        sharedPreferences.setString('access_token', jsonResponse['accessToken']);
        sharedPreferences.setString('password', passwordController.text);
        String rr=await repository.updatetokken(jsonResponse['user']['_id'], devicetokken,jsonResponse['accessToken']);
        log(rr);
        Navigator.of(context).pushNamed('/NavBar', arguments: RouteArgument(currentTab: 0, heroTag: "0"));
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Login failed'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Login failed'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
    setState((){loading = false;});
  }

  register(String token) async{
    setState((){loading = true;});
    String gender = '0';
    if(maleCheck) {
      gender = '0';
    }
    if (femaleCheck){
      gender = '1';
    }
    if (businessCheck){
      gender = '2';
    }
    try{

      String response =await repository.userRegister(assignednumber, passwordController.text, assignednumber, gender,token);
      final jsonResponse = json.decode(response);

      if(jsonResponse['success'] == true){

        accountnumber=assignednumber;
        login();
        // showDialog(
        //     context: context,
        //     builder: (context) {
        //       return AlertDialog(
        //         title: Text('Successfully Registered.'),
        //         actions: <Widget>[
        //           TextButton(
        //               onPressed: () {
        //                 Navigator.pop(context);
        //               },
        //               child: Text('close'))
        //         ],
        //       );
        //     }).then((value) {
        //
        // });
      }
      else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Register failed\n'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Register failed\n'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }

  }

  sendRetrieveMail() async{
    try{
      String response =await repository.sendEmail(emailController.text.trim());
      final jsonResponse = json.decode(response);
      if(jsonResponse['success'] == true){
        print('code------------' + jsonResponse['code'].toString());
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RetrieveCodeWidget(emailController.text.trim(), jsonResponse['code'], jsonResponse['user_id'])));
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Mail Send failed'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Mail Send failed'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }


  resendMail(String email) async{
    try{
      String response =await repository.sendEmail(email);
      final jsonResponse = json.decode(response);
      if(jsonResponse['success'] == true){
        print('code------------' + jsonResponse['code'].toString());
        return jsonResponse['code'];
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Mail Send failed'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Mail Send failed'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }

  resetPassword(String user_id, String trim) async{
    try{
      String response =await repository.reset_password(user_id, trim);
      final jsonResponse = json.decode(response);
      if(jsonResponse['error'] == false){
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Successfully changed'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            }).then((value) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacementNamed('/Login');
        });
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Error'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }

  sendRegisterVerification() async{

    try{
      String response =await repository.sendRegisterEmail(emailController.text.trim());
      final jsonResponse = json.decode(response);
      if(jsonResponse['success'] == true){
        print('code------------' + jsonResponse['code'].toString());
        setState(() {
          registerVerificationCode = jsonResponse['code'];
        });
        Fluttertoast.showToast(msg: 'The email containing the verification code has been sent.');
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Mail Send failed'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('close'))
                ],
              );
            });
      }
    } catch(err) {
      setState(() {
        registerVerified = true;
      });
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Mail Send failed'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }
  getallnumbers(int index)
  async {
    setState((){loading = true;});
      String response =await repository.getnumbers(index);
      final jsonResponse = json.decode(response);
      final responses = json.decode(response);

        final data = responses['data'] as List;
        log(response);
      return responses;

  }
  getPrivacyPolicy() async {
    try{
      String response =await repository.getPrivacyPolicyRepo();
      final jsonResponse = json.decode(response);
      if(jsonResponse['success']) {
         setState(() {
           privacyPolicyData = jsonResponse['content'];
           userPolicyDataLoaded = true;
         });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Failed"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }

  getUserAgreement() async {
    try{
      String response =await repository.getUserAgreementRepo();
      final jsonResponse = json.decode(response);
      if(jsonResponse['success']) {
        setState(() {
          userAgreement = jsonResponse['content'];
          userAgreementDataLoaded = true;
        });
      }
    } catch(err) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Failed"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('close'))
              ],
            );
          });
    }
  }

}
