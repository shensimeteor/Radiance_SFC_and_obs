#!/usr/bin/perl

$GMID="GECHRAR";
$MEMBER="GNL_WCTRL";
$start_cycle="2017061213";
$end_cycle="2017061213";
$cycle_interval = 6;
$start_hour=0;
$end_hour=170;
$incre_hour=1;
$dom=2;
$do_save=1; #do or don't save aux files on disk
$do_plot_sfc_obs = 0; #Plot
$do_error_calc = 0; #calc error and output
$do_wrf_obs_match = 1; #match wrf,obs variables and output

$HOMEDIR="/data1/fdda-ops/";
#$GMODDIR="$HOMEDIR/data/GMODJOBS/$GMID";
$ENSPROCS="$HOMEDIR/fddahome/cycle_code/CSH_ARCHIVE/ncl";
$RUNDIR="$HOMEDIR/data/cycles/$GMID/reanl/$MEMBER/2017/201706";
$ARCDIR="$HOMEDIR/data/cycles/$GMID/archive/$MEMBER/"; #aux_$CYCLE #no need
$WORKDIR="/dev/shm/ObsRadiancePlot/$GMID/$MEMBER";
$ROOTDIR="$HOMEDIR/sishen/Plot_Radiation_SfcObs/";
$SRC_DIR="$ROOTDIR/src";
$OUT_DIR="$ROOTDIR/output";
$OBS_DIR="$ROOTDIR/Radiation_OBS_timeadjust/output";
require "$ENSPROCS/common_tools.pl";

$CYCLE = $start_cycle;
while ( 1 ) {
    if ($CYCLE > $end_cycle) {
        last;
    }
    print "\n START CYCLE: $CYCLE -------------------- \n";
    $TEMPDIR="$OUT_DIR/temp_aux/$CYCLE"; #save aux.nc file
    $PLOTDIR="$OUT_DIR/output_png/$CYCLE";
    $ERRORDIR = "$OUT_DIR/output_error/$CYCLE";
    $MATCHDIR= "$OUT_DIR/output_match/$CYCLE";
    
    if($do_plot_sfc_obs) {
        system("test -d $PLOTDIR || mkdir -p $PLOTDIR");
    }
    if($do_save) {
        system("test -d $TEMPDIR || mkdir -p $TEMPDIR");
    }
    if($do_error_calc) {
        system("test -d $ERRORDIR ||mkdir -p $ERRORDIR");
    }
    if($do_wrf_obs_match) {
        system("test -d $MATCHDIR ||mkdir -p $MATCHDIR");
    }

    for ($hr=$start_hour; $hr <=$end_hour; $hr=$hr+$incre_hour) {
        $d=&tool_date12_add("${CYCLE}00", $hr, "hour");
        print("to process $d -----\n");
        $bjd=$d;
        if($hr < 0){
            $end="_F";
        }else{
            $end="_P";
        }
        $mywork="$WORKDIR/$CYCLE/$d/";
        system("test -d $mywork || mkdir -p $mywork");
        chdir($mywork);
        #cp aux
        $file_name2_nc3=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc");
        $file_temp_save="$TEMPDIR/$file_name2_nc3";
        if( -e $file_name2_nc3) {
            print "file exists in /dev/shm\n";
            if( !-e $file_temp_save && $do_save ) { 
                system("cp -r $file_name2_nc3 $TEMPDIR/");
            }
        }elsif (-e $file_temp_save) { 
            print "file exists in temp dir, to cp\n";
            system("cp -r $file_temp_save $mywork/");
        }else{
            if( $hr < 0) {
                $file_name1=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", "");
                $file_path1="$RUNDIR/$CYCLE/WRF_F/$file_name1";
                $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc4.p");
                $file_path2="$ARCDIR/aux3_final/$file_name2";
            }else{
                $file_name1=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", "");
         #       $file_path1="$RUNDIR/$CYCLE/WRF_P/$file_name1";
                $file_path1="$RUNDIR/$file_name1";
                $file_name2=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}00", ".nc4.p");
                $file_path2="$ARCDIR/aux3_$CYCLE/$file_name2";
            }
            if( -e $file_path1) {
                print("file exists in WRF_F/WRF_P run dir, to cp\n");
                system("cp -r $file_path1 $mywork/$file_name2_nc3");
            }elsif (-e $file_path2) {
                print("file exists in aux archive dir, to cp\n");
                system("cp -r $file_path2 $mywork/");
                $file_name2_unpack=&tool_date12_to_outfilename("auxhist3_d0${dom}_", "${d}", ".nc4");
                print("doing ncpdq unpacking..\n");
                system("ncpdq -O -U $file_name2 $file_name2_unpack && rm -rf $file_name2");
                print("doing nc4 to nc3..\n");
                system("ncks -O -3 $file_name2_unpack $file_name2_nc3");
                if( $do_save) {
                    system("cp $file_name2_nc3 $TEMPDIR/");
                }
            }else {
                print("WARN: aux file not found , next \n");
                next;
            }
        }
        $file_path="$mywork/$file_name2_nc3";
        #cp obsfile
        $obs_file="$OBS_DIR/${bjd}_Radiation.txt";
        if( ! -e $obs_file ) {
            print("WARN: $obs_file not found, next \n");
            next;
        }
        system("cp $obs_file $mywork");
        print("$obs_file\n");
        #ln ncl
        symlink("$SRC_DIR/plot_SFC_and_obs_SW_txt.ncl", "plot_SFC_and_obs_SW_txt.ncl");
        symlink("$SRC_DIR/read_obs_radiance_txt.ncl", "read_obs_radiance_txt.ncl");
        symlink("$SRC_DIR/calc_Radiance_Wrf_Error.ncl", "calc_Radiance_Wrf_Error.ncl");
        symlink("$SRC_DIR/match_allRadiation_wrf_obs.ncl", "match_allRadiation_wrf_obs.ncl");
        #run ncl
        if($do_plot_sfc_obs) {
            $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' plot_SFC_and_obs_SW_txt.ncl > log.ncl);
            print($cmd."\n");
            system($cmd);
            #cpout png & rm workdir
            system("cp 20*/*png $PLOTDIR/${d}_d2_swdown.png");
        }
        if($do_error_calc){
            $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' calc_Radiance_Wrf_Error.ncl > log.calc);
            print($cmd."\n");
            system($cmd);
            system("cp output.txt $ERRORDIR/${d}_d2_swdown.txt");
        }
        if($do_wrf_obs_match) {
            $cmd=qq(ncl 'file_in="$file_name2_nc3"' 'obs_txt_file="$obs_file"' match_allRadiation_wrf_obs.ncl >log.match);
            print($cmd."\n");
            system($cmd);
            system("cp output_wrfobs.txt $MATCHDIR/${d}_d2_wrfobs.txt");
        }
        chdir("$WORKDIR/$CYCLE");
        system("rm -rf $mywork");
    }

    $CYCLE00="${CYCLE}00";
    $CYCLE00 = &tool_date12_add($CYCLE00, $cycle_interval, "hour");
    $CYCLE = substr($CYCLE00, 0, 10);
}
