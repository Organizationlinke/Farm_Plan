import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
var user_id;
int user_level=0;
var user_area;
int new_level=0;
String New_user_area='' ;
// var Old_user_area ;
var check_farm;
var farm_title;
var old_check_farm;
int user_type=1;
var user_respose;

const Colorapp =Color.fromARGB(255, 120, 60, 255);

const colorbar=  Color.fromARGB(255, 206, 201, 219);
const color_under= Color.fromARGB(255, 192, 144, 0);
const color_finish=Colors.green;
const color_cancel=Colors.red;



void checked(){
 new_level==2?check_farm='area':
new_level==3?check_farm='sector':
new_level==4?check_farm='reservoir':
check_farm='section';
old_checked();
}
void old_checked(){
 new_level==3?old_check_farm='area':
new_level==4?old_check_farm='sector':
new_level==5?old_check_farm='reservoir':
old_check_farm='farm';
}

