! 
! Subroutine to extract iLat, iLon, dx, dy, 
! from tmp file that has lat/long/U/lat/lon/V
!
  subroutine header_fort222(tmp, num_cell_corners, iLon, iLat, dx, dy, swlat, swlong)
!
  real, dimension(10000000,9), intent(in) :: tmp
  real, intent(out)                      :: swlong, swlat
  real, intent(out)                      :: dx, dy
  real                                   :: lon0, lat0
  integer, intent(in)                    :: num_cell_corners
  integer, intent(out)                   :: iLat, iLon
  integer                                :: k
!
! Grab the iLat and iLon
! Saving the 1st lat and lon
! First occurrance of the same lat lon shows iLat+1 & iLon+1
  lon0 = tmp(1,1)
  lat0 = tmp(1,2)
  do k=2,num_cell_corners
     if ( lon0.eq.tmp(k,1) ) then
        iLon = k - 1
        go to 10
     endif
  enddo
!
10 continue
!
! Latitudes are changing evey iLon
  do k=(iLon+1),num_cell_corners+iLon,iLon
     if ( lat0.eq.tmp(k,2) ) then
        iLat = k - 1
        go to 11
     endif
  enddo
!
11 continue
!
! Correction
  iLat=iLat/iLon
!
! Getting dx and dy 
  dx = tmp(2,1) - tmp(1,1)
  dy = tmp(iLon+1,2) - tmp(1,2)
!
! Getting the southwest lat and lon which are in the 1st row
  swlong = tmp(1,1)
  swlat  = tmp(1,2)
  end subroutine 
