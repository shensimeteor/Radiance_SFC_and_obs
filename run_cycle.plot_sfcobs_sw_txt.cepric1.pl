#!/usr/bin/perl

$GMID="GECHRAR";
$MEMBER="GNL_WCTRL";
$CYCLE="2017061213"; #actually month
$start_hour=0;
$end_hour=170;
$incre_hour=1;
$dom=2;

$do_plot_sfc_obs=0;
$do_error_output=1;

$HOMEDIR="/data1/fdda-ops/";
#$GMODDIR="$HOMEDIR/data/GMODJOBS/$GMID";
$ENSPROCS="$HOMEDIR/fddahome/cycle_code/CSH_ARCHIVE/ncl";
$RUNDIR="$HOMEDIR/data/cycles/$GMID/reanl/$MEMBER/2017/201706";
$ARCDIR="$HOMEDIR/data/cycles/$GMID/archive/$MEMBER/"; #aux_$CYCLE #no need
$OBSDIR="$HOMEDIR/sishen/Plot_Radiation_SfcObs/Radiation_OBS_timeadjust/output/";
$WORKDIR="/dev/shm/ObsRadiancePlot/$GMID/$MEMBER";
$SCRIPT_DIR="$HOMEDIR/sishen/Plot_Radiation_SfcObs/Radiance_SFC_and_obs/";
$TEMPDIR="$SCRIPT_DIR/temp_aux/$CYCLE"; #save aux.nc file, only for archived files
$PLOTDIR="$SCRIPT_DIR/output_png/$GMID/";
$STATDIR="$SCRIPT_DIR/output_stats/$GMID/";
require "$ENSPROCS/common_tools.pl";

for ($hr=$start_hour; $hr <=$end_hour; $hr=$hr+$incre_hour) {
    $d=&tool_date12_add("${CYCLE}00", $hr, "hour");
    print("to process $d -----\n");
    #$bjd=&tool_date12_add($d, 8, "hour");
    $bjd=$d;
    $mywork="$WORKDIR/$CYCLE/$d/";
    system("test -d $mywork || mkdir -p $mywork");
    chdir($mywork);
    #cp aux
    $file_name2_nc3=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc");
    $file_temp_save="$TEMPDIR/$file_name2_nc3";
    $file_name1=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", "");
    $file_path1="$RUNDIR/$file_name1";
    $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4.p");
    $file_path2="$ARCDIR/aux3_$CYCLE/$file_name2";
    if( -e $file_name2_nc3) {
        print "file exists in /dev/shm\n";
        if( !-e $file_temp_save) { 
            system("cp -r $file_name2_nc3 $TEMPDIR/");
        }
    }elsif (-e $file_temp_save) { 
        print("cp -r $file_temp_save $mywork/");
        system("cp -r $file_temp_save $mywork/");
    }elsif (-e $file_path1) {
        system("cp -r $file_path1 $mywork/$file_name2_nc3");
    }elsif (-e $file_path2) {
        system("cp $file_path2 $mywork/");
        $file_name2_unpack=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4");
        print("doing ncpdq unpacking..\n");
        system("ncpdq -O -U $file_name2 $file_name2_unpack && rm -rf $file_name2");
        print("doing nc4 to nc3..\n");
        system("ncks -O -3 $file_name2_unpack $file_name2_nc3");
        system(" test -d $TEMPDIR || mkdir -p $TEMPDIR");
        system("cp $file_name2_nc3 $TEMPDIR/");
    }else {
        print("aux file not found , next \n");
        next;
    }
    $file_path="$mywork/$file_name2_nc3";
    #cp obsfile
    $obs_file="$OBSDIR/${bjd}_Radiation.txt";
    if( ! -e $obs_file ) {
        print("$obs_file not found, next \n");
        next;
    }
    system("cp $obs_file $mywork");
    print("$obs_file\n");
    #ln ncl
    symlink("$SCRIPT_DIR/plot_SFC_and_obs_SW_txt.ncl", "plot_SFC_and_obs_SW_txt.ncl");
    symlink("$SCRIPT_DIR/read_obs_radiance_txt.ncl", "read_obs_radiance_txt.ncl");
    symlink("$SCRIPT_DIR/calc_Radiance_Wrf_Error.ncl", "calc_Radiance_Wrf_Error.ncl");
    #run ncl
    if($do_plot_sfc_obs) {
        $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' plot_SFC_and_obs_SW_txt.ncl > log.plot);
        print($cmd."\n");
        system($cmd);
        system("test -d $PLOTDIR || mkdir -p $PLOTDIR");
        system("cp 20*/*png $PLOTDIR/${d}_d2_swdown.png");
    }
    if($do_error_output) { 
        $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' calc_Radiance_Wrf_Error.ncl > log.calc);
        print($cmd."\n");
        system($cmd);
        system("test -d $STATDIR || mkdir -p $STATDIR");
        system("cp output.txt $STATDIR/${d}_d2_swdown.txt");
    }
    chdir("$WORKDIR/$CYCLE");
    system("rm -rf $mywork");
}





