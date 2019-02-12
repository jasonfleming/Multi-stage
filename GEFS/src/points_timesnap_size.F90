!
  subroutine points_timesnap_size(tmp, ensemble_num, num_cell_corners, output_snap_num)
!
  real, dimension(10000000,9), intent(in) :: tmp
  integer, intent(in)         :: ensemble_num   
  integer                     :: i, a
  integer                     :: arrange
  integer, intent(out)        :: num_cell_corners
  integer                     :: length_tmp
  integer, intent(out)        :: output_snap_num
  integer                     :: hr
  integer                     :: h
  integer                     :: j
  integer                     :: ens_num
  integer                     :: io
  real                        :: lat0, lon0
 
!
! getting the length of the tmp
! since 1000000 rows have been assigned, the first zero
! that we encounter indicates the end of file
  do i=1,10000000
     a=tmp(i,1)
     if ( a.eq.0 ) then
        length_tmp  = i-1
        write(*,*) " The size of unformatted UV file is", i-1
        go to 111
     endif
  enddo
!
111 continue
!
! getting the number of data points at each time step
! Lets say 1st time step starts with a lat0 and lon0
! The first occuring lat and lon equals to 
! lat0 and lon0 indicates that output
! on the next time step has started
  lon0=tmp(1,1)
  lat0=tmp(1,2)
  do i=2,length_tmp
      if (( tmp(i,1).eq.lon0 ) .and. (tmp(i,2).eq.lat0)) then
          num_cell_corners  = i-1
          write(*,*) " The number of cell corners", i-1
          go to 112
      endif
  enddo
112 continue
!
! Calculating the number of output snaps knowing the number
! of ensembles. 
  output_snap_num = length_tmp/ensemble_num/num_cell_corners
  write(*,*) " The number of output snaps in each ensemble run is ",output_snap_num
!
end subroutine 
