c $Header: /cvs/ppgen/src/rcovalent.f,v 1.1.1.1 2005/11/01 09:58:22 jelen Exp $
c default (covalent) radii for the elements used for log derivatives
      real*8 function rcovalent(z)
      implicit none
      include 'parameter.h'
      integer z
      real*8  rdv(mzmx)
      data rdv/0.60,1.76,
     & 2.33,1.70,1.55,1.46,1.42,1.38,1.36,1.34,
     & 2.91,2.57,2.23,2.10,2.00,1.93,1.87,1.85,
     & 3.84,3.29,
     & 2.72,2.50,2.31,2.23,2.21,2.21,2.19,2.17,2.21,2.36,
     &           2.38,2.31,2.27,2.19,2.16,2.12,
     & 4.08,3.61,
     & 3.06,2.74,2.53,2.46,2.40,2.36,2.36,2.42,2.53,2.80,
     &           2.72,2.67,2.65,2.57,2.51,2.48,
     & 4.44,3.74,
     & 3.19,3.12,3.12,3.10,3.08,3.06,3.50,3.04,3.01,3.01,2.99,
     & 2.97,2.95,2.95,2.95,
     & 2.72,2.53,2.46,2.42,2.38,2.40,2.46,2.53,2.82,
     &           2.80,2.78,2.76,2.76,2.74,2.71,
     & 4.82,3.88,
     & 3.31,3.12,3.00,3.00,3.00,3.00,3.00,3.00,3.00,3.00,3.00,3.00,
     & 5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,
     & 5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00/

      if(z.lt.1 .or. z.gt.mzmx) then
        write(ie,'(a/,a,i4,a)')
     1    '%rcovalent - ERROR: no default covalent radius implemented',
     1    ' for z=',z,' likely z is too large. ACTION: contact author.'
        stop
      endif

      rcovalent=rdv(z)

      return
      end
