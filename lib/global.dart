int user_level=0;
var user_area;
int new_level=0;
String New_user_area='' ;
// var Old_user_area ;
var check_farm;
var farm_title;
var old_check_farm;
// var Old_user_area_1 ;
// var Old_user_area_2 ;
// var Old_user_area_3 ;
// var Old_user_area_4 ;
// var Old_user_area_5 ;

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

// void Old_user_area_IN(){
//   print('aa:$new_level');
// if (new_level==1) {
//   Old_user_area_1=New_user_area;
//   print('Old_user_area_1:$Old_user_area_1');
// }
// if (new_level==2) {
//   Old_user_area_2=New_user_area;
//     print('Old_user_area_2:$Old_user_area_2');
// }
// if (new_level==3) {
//   Old_user_area_3=New_user_area;
//    print('Old_user_area_3:$Old_user_area_3');
// }
// if (new_level==4) {
//   Old_user_area_4=New_user_area;
//    print('Old_user_area_4:$Old_user_area_4');
// }
// if (new_level==5) {
//   Old_user_area_5=New_user_area;
//     print('Old_user_area_5:$Old_user_area_5');
// }
// }
// void Old_user_area_OUT(){
//   print('bb:$new_level');
// if (new_level==1) {

//   Old_user_area=Old_user_area_1;
  
// }
// if (new_level==2) {
 
//   Old_user_area=Old_user_area_2;
// }
// if (new_level==3) {

//   Old_user_area=Old_user_area_3;
// }
// if (new_level==4) {
 
//   Old_user_area=Old_user_area_4;
// }
// if (new_level==5) {

//   Old_user_area=Old_user_area_5;
// }
//   print('Old_user_area:$Old_user_area');
// }
