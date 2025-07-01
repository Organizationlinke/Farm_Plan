import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
var user_id;
int user_level=0;
var user_area;
var user_uuid;
int new_level=0;
String New_user_area='' ;
String New_user_area2='' ;
int new_level2=0;
// var Old_user_area ;
var check_farm;
var check_farm2;
var farm_title;
var old_check_farm;
var old_check_farm2;
int user_type=1;
var user_respose;
List<String> user_responsible_areas = [];

// const Colorapp =Color.fromARGB(255, 120, 60, 255);
const Colorapp=Colors.white;
const colorbar=  Color.fromARGB(255, 1, 131, 5);
// const colorbar=  Color.fromARGB(255, 218, 236, 208);
const colorbar_bottom=  Color.fromARGB(255, 206, 201, 219);
const MainFoantcolor=  Color.fromARGB(255, 2, 13, 160);
const color_under= Color.fromARGB(255, 192, 144, 0);
const color_finish=Colors.green;
const color_cancel=Colors.red;
const color_Button=Color.fromARGB(255, 1, 131, 5);
List<String> selectedAreas = [];
List<String> selectedAreas2 = [];


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

void checked2(){
 new_level2==2?check_farm2='area':
new_level2==3?check_farm2='sector':
new_level2==4?check_farm2='reservoir':
check_farm2='section';
old_checked2();
}
void old_checked2(){
 new_level2==3?old_check_farm2='area':
new_level2==4?old_check_farm2='sector':
new_level2==5?old_check_farm2='reservoir':
old_check_farm2='farm';
}

