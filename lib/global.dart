int user_level=0;
var user_area;
int new_level=0;
var New_user_area ;
var Old_user_area ;
var check_farm;
var farm_title;
var old_check_farm;

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
