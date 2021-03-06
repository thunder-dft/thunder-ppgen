c Header:$
cmf 27-06-03 added spin polarization for selected xc functionals
cmf 04-09-02 added kli exchange functional
c
      program pslp
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c FHI pseudopotential tool's
c
c              beta version as of 27-06-2003
c
c Except for some cleanup and fine tuning this may be about the final
c version. If you encounter bugs or have some comments, I would like to
c to hear about them. Of course you may use this program freely, but
c please do not redistribute it. Until the final version is released
c I would appreciate if interested parties obtained their copies from
c me instead. Please give proper credit as indicated below.
c
c Martin Fuchs     fuchs@fhi-berlin.mpg.de
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c-----------------------------------------------------------------------
c Pseudopotential analyzing routine for semilocal pseudopotentials
c - self-consistent electronic structure for pseudo atom
c - local density/ generalized gradient approximation,
c   some useable for spin-polarized calculation
c - kinetic energy-density dependent functionals (experimental)
c - exact kohn-sham exchange within kli approximation (experimental)
c - linearized/ nonlinear core-valence exchange-correlation
c - valuation of separable Kleinman-Bylander (KB) representation 
c   * calculation of logarithmic derivatives
c   * search for ghost states (cf Ref [1])
c   * bound state spectrum w/ basis of orthogonal polynomials
c    (a crude method for any excited state, yet sufficient here)
c
c Familiarity with the references below should be regarded as a 
c prerequisite to a profitable use of this program. 
c Please cite these references when publishing results obtained with
c pseudopotentials constructed with the help of this program.
c
c [1] X. Gonze, R. Stumpf, M. Scheffler, Phys. Rev. B 44, 8503 (1991)
c     "Analysis of separable potentials"
c
c [2] M. Fuchs, M. Scheffler, Comput. Phys. Commun. 119, 67-98 (1999)
c
c Martin Fuchs
c Fritz-Haber-Institut der Max-Planck-Gesellschaft
c Abteilung Theorie
c Faradayweg 4-6
c D-14195 Berlin - Dahlem
c Germany
c E-mail: fuchs@fhi-berlin.mpg.de
c-----------------------------------------------------------------------
c
c input files
c
c fort.21    control parameters 
c fort.22    atomic parameters 
c fort.31    semilocal ionic pseudopotential (fhi94md format)
c fort.37    all-electron (reference) potential 
c
c output
c
c log. derivatives
c fort.6[l = 0,1,2...]	all-electron case
c fort.5[l = 0,1,2...]	semilocal case
c fort.7[l = 0,1,2...]	separable case (sbrt. klbyan)
c
c fort(iu)    monitoring data, ghost state analysis (-> parameter.h)
c fort.27     modelcore density
c fort.38     pseudo wavefunctions
c fort.4[0-4] ionic pseudopotentials
c fort.4[5-9] screened pseudopotentials
c fort.80     info file for kli case
c-----------------------------------------------------------------------
c
c input description fort.21 and fort.22
c
c fort.21 - line 1
c l_loc  angular momentum for local potential
c lbeg   dto. lowest  for evaluating logarithmic derivatives
c lend   dto. highest for evaluating logarithmic derivatives
c lmax   dto. maximum represented by pseudopotentials
c rld    diagnostic radius for evaluating logarithmic derivatives
c
c fort.21 - line 2
c tlgd   .true.  compute logarithmic derivatives
c tkb    .true.  perform ghost state analysis
c tiwf   .true.  use input wavefunctions to make nonlocal potentials
c tnrl   .true.  assume pseudopotentials are nonrelativistic
c        default is .false. (scalar-relativistic pseudopotentials)
c
c fort.21 - line 3
c tcut_global    .true.  before calculating anything, enforce a
c                 Coulomb tail in pseudopotential for radii beyond
c rcut_global    global cutoff radius. Default is .false. . The
c                 modified pseudopotential is written out.
c
c fort.21 - line 4
c tspin  .true.  perform a spin-polarized calculation.
c        Default is .false. . Implemented for selected xc functionals
c        only. Requires modified input file fort.22 .
c
c fort.22 - line 1
c zfull  atomic number
c nc     number of core states 
c nv     number of valence states
c iexc   exchange-correlation functional
c        an S indicates valid spin-polarized functionals
c         1  LDA   Wigner
c         2  LDA   Hedin/Lundqvist
c         3  LDA   Ceperley/Alder Perdew/Zunger (1980)           
c         4 SGGA   Perdew/Wang (1991)
c         5 SGGA   Becke (1988) X, Perdew (1986) C
c         6 SGGA   Perdew/Burke/Ernzerhof (1996)
c         7  LDA   Zhao/Parr
c         8 SLDA   Ceperley/Alder Perdew/Wang (1991)
c         9  GGA   Becke (1988) X, Lee/Yang/Parr (1988) C
c        10  GGA   Perdew/Wang (1991) X, Lee/Yang/Parr (1988) C
c        11  LDA   exchange only
c        12  KLI   excact Kohn-Sham exchange in the Krieger et al.
c                  approximation
c        13  KLI   KLI+effective core potential
c        14  GGA   Hammer/Norskov revised PBE GGA (RPBE)
c        15  GGA   Zhang/Wang revised PBE GGA (revPBE)
c        16  MGGA  Perdew/Kurth/Zupan/Blaha MetaGGA (1999)
c        17  GGA   GGA exchange + LDA correlation, PBE X, LDA C
c        18  KLI   exact exchange + LDA correlation
c        19  KLI   exact exchange + PBE GGA correlation
c        default is 8
c rnlc   pseudocore radius 
c
c fort.22 - line 2 etc.
c n(i)   principal quantum number
c l(i)   angular momentum
c f(i)   occupation number (two entries for spin-polarized mode)
c
c sample input fort.21 for silicon (3s3p3d potentials)
c > 2 0 2 2 0.0     : l_loc lbeg lend lmax rld
c >.t. .t. .t. .f.  : tlgd  tkb  tiwf tnrl
c
c sample input fort.22 for silicon (LDA, linearized CV XC)
c > 14.0 3 2 8 0.0  : z nc nv iexc rnlc
c > 1   0  2.0      : n l f
c > 2   0  2.0
c > 2   1  6.0
c > 3   0  2.0
c > 3   1  2.0
c excess lines are not read
c
c sample input fort.22 for silicon (LSDA, linearized CV XC)
c > 14.0 3 2 8 0.0  : z nc nv iexc rnlc
c > 1   0  1.0 1.0  : n l f
c > 2   0  1.0 1.0
c > 2   1  3.0 3.0
c > 3   0  1.0 1.0
c > 3   1  2.0 0.0
c excess lines are not read
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      logical tkb,tins,terr,tnlc,tlgd,tnrl,tiwf,tcut_global,tspin
      character*8 symz,symxc*40,srev*10
      character*1 sn,sl,sm

      include 'parameter.h'
      include 'default.h'

      parameter(rmx=80.d0)

c &&&&&&&&&&&&& REVISION &&&&&&&&&&&&&
      parameter(srev='rev270603B')

      integer   ir,iu,mmaxtmp
      integer   np(ms),lp(ms),n(ms),m(ms),l(ms),ntl(ms),ninu(ms)
      real*8    f(ms),fp(ms),e(ms),rdv(100),vps(mx,ms)
      real*8    r(mx),vi(mx),ves(mx),vxc(mx,ms),vee(mx,ms),ups(mx,ms)
      real*8    vae(mx),ep(ms),igrmap(20),dummy(ms),uout(mx,ms)
      real*8    uu(mx,ms),vbare(mx,ms),vorb(mx,ms),vsl(mx)
      real*8    dc(mx),dcp(mx),dcpp(mx),rho(mx),rhop(mx),rhopp(mx)
      real*8    rhos(mx,ms),rhosp(mx,ms),rhospp(mx,ms)
      real*8    rxx(mx),vvo(mx),rc(ms)
      real*8    x_l(mx),vbare_l(mx,ms)

      real*8  dexc
      common/xced/dexc(mx)

c kli
      logical tkli
      real*8  svm(ms),svm_roks(ms),svkli(ms)
c meta gga
      logical tmgga
      real*8  stat,stat_core
      common/use_mgga/stat(mx),stat_core(mx)

      external  dmelm,gltfmv,fmom,rcovalent

      data igrmap/0,0,0,1,1,1,0,0,1,1,0,0,0,1,1,1,1,0,1,0/
c
c begin 
c output unit
      iu=iopslp
c defaults
      iexc=8
      lmax=2
      lbeg=0
      lend=lmax
      l_loc=lmax
      rld=0.d0
c do log derivatives tlgd=.true. 
      irl=1
      tcut_global=.false.
      rcut_global = 1e3
      tiwf=.true.
      tkb=.true.
      tkli=.false.
      tlgd=.true.
      tnlc=.false.
      tnrl=.false.
      tmgga=.false.
      tspin=.false.
c log file
      write(iu,619) srev
c initialize
      do i=1,ms
        fp(i)=0.d0
        f(i)=0.d0
        f(i)=0.d0
        n(i)=0
        l(i)=0
      enddo
      ispinmx=1

c header file
      read(21,*,err=10,end=10) l_loc,lbeg,lend,lmax,rld
   10 read(21,*,err=11,end=11) tlgd,tkb,tiwf,tnrl
   11 read(21,*,err=12,end=12) tcut_global,rcut_global
   12 read(21,*,err=13,end=13) tspin
   13 if(tspin) ispinmx=2 
c debug
!     write(ie,*) '%pslp - ispin,tspin=',ispinmx,tspin

      read(22,*,err=14,end=14) zfull,nc,nv,iexc,rnlc
      zfull=abs(zfull)
      nc=abs(nc)
      nv=abs(nv)
      imx=nc+nv
      do i=1,imx
        if(ispinmx.eq.1) then
          read(22,*,err=14,end=14) np(i),lp(i),fp(i)
        else
          read(22,*,err=14,end=14) np(i),lp(i),fp(i),fp(i+imx)
        endif
        fp(i)=abs(fp(i))
        fp(i+imx)=abs(fp(i+imx))
        if(np(i) .le. lp(i)) stop 'pslp - data: l .le. n'
        if(lp(i) .gt. 3)     stop 'pslp - data: l .gt. 3'
        npmax=max(np(i),npmax)
      enddo
   14 imx=i-1
      if(ispinmx.gt.1) then
        do i=1,imx
c for occupation of spin states ...
          if(fp(i+imx).eq.0.d0) then
c ... follow 2nd Hund rule
            fup=min(fp(i),2.d0*lp(i)+1.d0)
            fdn=fp(i)-fup
          else
            if(fp(i).gt.fp(i+imx)) then
c ... follow fixed majority spin
              fup=fp(i+imx)
              fdn=fp(i)-fup
            else
c ... use occupancies of input
              fup=fp(i)
              fdn=fp(i+imx)
            endif
          endif
          fp(i)=fup
          np(i+imx)=np(i)
          lp(i+imx)=lp(i)
          fp(i+imx)=fdn
        enddo
      endif  
c debug
!     write(ie,*) '%pslp - state count: imx=', imx,' of',(nc+nv)*ispinmx
!     do i=1,imx
!       write(ie,*) np(i),lp(i),fp(i),np(i+imx),lp(i+imx),fp(i+imx)
!     enddo

      if(tnrl) irl=2
      if(abs(rnlc) .gt. 0.0) tnlc=.true.
      iexc=abs(iexc)
      if(iexc.eq.12 .or. iexc.eq.13 .or. iexc.eq.18 .or.
     1   iexc.eq.19 .or. iexc.eq.16) tkli=.true.
      igr=igrmap(iexc)
      igr=1
      if(iexc .eq. 16) tmgga = .true. 	! meta gga
c map for spin polarized calculation
      if(ispinmx.gt.1) then
        iexcs=3
        if(iexc.eq.3 .or. iexc.eq.8) then
          iexcs=3                !LDA
        else if(iexc.eq.5) then
          iexcs=5                !BP GGA
        else if(iexc.eq.4) then  
          iexcs=6                !PW91 GGA
        else if(iexc.eq.6) then
          iexcs=9                !PBE GGA
        else
          write(ie,'(a/,a,i3,a)')
     1      '%pslp - ERROR: spin polarized calculation not implemented',
     1      ' for input iexc=',iexc,'. ACTION: set iexc=3,4,5,6,8.'
          stop
        endif
      endif

c open files
      if(tkli) open(unit=80,file='kliinfoPS.dat',status='unknown')

      lmax=max(0,lmax)
      l_loc=max(0,min(l_loc,lmax))
      lbeg=max(0,lbeg)
      lend=max(lbeg,min(lend,5))
      llmx=lmax+1
      llbeg=lbeg+1
      llend=lend+1
      ll_loc=l_loc+1
! jel
! OFS storing information about (non)local parts into a file 
      open (unit=77, file='lmaxNlloc.dat', status='unknown')
      write (77,*) lmax,'         This is lmax 0=s,1=p,2=d,3=f etc.'
      write (77,*) l_loc,'         This is l_loc, the local pseudo.'
      do ll = 0,lmax
       if (ll .ne. l_loc) then 
         write(77,*) ll,'          ! This L value has a non-local PP'
       endif
      enddo
      close (unit=77)
! jel-end

      do ll=1,llmx
        n(ll)=ll
        l(ll)=ll-1
      enddo

      cval=0.d0
      norb=0
      do ispin=1,ispinmx
        norbstart=norb+1
        istart=nc*ispin+nv*(ispin-1)+1
        iend=istart+nv-1
c debug
!       write(ie,*) '%pslp - istart=',istart,' iend=',iend
        do i=istart,iend
          norb=norb+1
          n(norb)=lp(i)+1
          do j=norbstart,norb-1
            if(l(j) .eq. lp(i)) n(norb)=n(norb)+1
          enddo
          l(norb)=lp(i)
          f(norb)=fp(i)
          m(norb)=ispin
          cval=cval+fp(i)
c debug
!         write(ie,*) 'norb,n,l,m,f',
!    1      norb,n(norb),l(norb),m(norb),f(norb)
        enddo
      enddo

c pseudopotentials, radial meshs assumed to be the same throughout !!!
c format same as for fhi94md 
      mmax=mx
      do ll=1,llmx
        terr=.true.
        read(31,*,end=58,err=58) mmax,amesh
        do i=1,mmax
          read(31,*,end=58,err=58) iunused,r(i),uu(i,ll),vbare(i,ll)
        enddo
        terr=.false.
   58   if(i .le. mmax) terr=.true.
        if(abs(amesh-r(2)/r(1)) .gt. 1e-10) terr=.true.
        if(terr) then
          write(ie,*) '& pslp - stop: bad pseudopotential file fort.31'
          write(ie,*) '&        current l,mmax,i ',ll-1,mmax,i
          write(ie,*) '& amesh as input          ',amesh
          write(ie,*) '& amesh set to r(2)/r(1)  ',r(2)/r(1) 
          amesh = r(2)/r(1)
        endif
      enddo
      do i=1,mmax
        read(31,*,end=60,err=60)  r(i),dc(i),dcp(i),dcpp(i)
      enddo
   60 if(tnlc .and. i .eq. 1) then 
        write(ie,'(a/,a)')
     1    '%pslp - ERROR: bad pseudopotential file fort.31, cannot',
     1    ' read core density. ACTION: check pseudopotential file.'
        stop
      endif
      if(.not. tnlc .and. i .gt. 1) then
        write(ie,*) '% pslp - pseudocore present (fort.31)'
        tnlc=.true.
      endif
      if(tnlc.and.tkli) then
          write(ie,'(a/,a,i3,a)')
     1      '%pslp - ERROR: core density not implemented',
     1      ' for iexc=',iexc,'. ACTION: set iexc=3,4,5,6,8.'
          stop
      endif

c meta gga read in core kinetic energy density
      do i=1,mmax
        stat(i) = 0.d0
        stat_core(i) = 0.d0
      enddo
      if(tnlc .and. tmgga) then
        do i=1,mmax
          read(17,*,end=81,err=81) rxx(i),stat_core(i)
        enddo
   81   if(i .eq. 1) then
           write(ie,*) '& pslp - warning: check length of file fort.17'
           write(ie,*) '&        core kinetic energy density'
        endif
        write(ie,*) '& pslp - warning: t_core = t_core_vW'
        do i=1,mmax
          stat_core(i) = 0.125*dcp(i)**2/max(1.d-12,dc(i))
        enddo
      endif  

c restrict range of radial mesh
      amesh=r(2)/r(1)
      al=log(amesh)
      do i=mmax,1,-1
        if(r(i) .lt. rmx) goto 69
      enddo
  69  mmax=i
      if(mod(mmax,2) .eq. 0) mmax=mmax-1

c apply global cutoff to potentials (set to coulomb tail)
      if(tcut_global) then
        write(ie,'(a,/,a,f8.4,a)') 
     1    ' %pslp - WARNING: the input pseudopotential is modified',
     1    '  by imposing a global cutoff at radius = ',rcut_global,'.'  
        do ll=1,llmx
          write(ie,'(a,1x,i1)') 
     1    '        .cutoff imposed for l =',ll-1
          do i=mmax,1,-1
            v_coulomb = -cval/r(i)
            if(r(i) .lt. rcut_global) exit
            vbare(i,ll)=v_coulomb+exp(-3.5*(r(i)-rcut_global)**2)
     1              *(vbare(i,ll)-v_coulomb)
          enddo
        enddo
        write(ie,*)
      endif

c self-consistent pseudoatom 
c initial eigenvalues
      iend=norb/ispinmx
      do i=1,iend
        fp(i)=f(i)
        if(tspin) fp(i)=fp(i)+f(i+iend)
c debug
!       write(ie,*) '%pslp - i,fp',i,fp(i)
      enddo
      call atomini(iend,mmax,cval,npmax,fp,r,vi,e)
      call dnuv(mx,1,mmax,0.d0,vi)

      do i=1,norb
        e(i)=-0.5d0*max(1.d0,sqrt(cval))
        do ll=1,llmx
          if(l(i)+1 .eq. ll ) then
            call dcpv(mx,1,mmax,vbare(1,ll),vorb(1,i))
          else if(l(i)+1 .gt. llmx ) then
            call dcpv(mx,1,mmax,vbare(1,ll_loc),vorb(1,i))
          endif
        enddo
      enddo
      do i=1,mmax							!new
c       vi(i)=-max(1.d0,cval)/r(i)
        vi(i)=-max(1.d0,sqrt(cval))/r(i)
        do ispin=1,ispinmx
          vee(i,ispin)=vi(i)
        enddo
      enddo								!new

c tell psatom when to do spin polarized calculation
      iexcnow=iexc
      if(ispinmx.gt.1) iexcnow=-iexcs 

      it=itmx
      call psatom(it,igr,iexcnow,0.d0,0,norb,n,l,f,m,e,nin,de,mmax,r
     &, vee,vorb,rhos,rhosp,rhospp,dc,dcp,dcpp,ups,tkli,svm,svm_roks)
      iexc=abs(iexc)

c compute total density to retain compatibility with existing code
      do i=1,mmax
        vi(i)=vee(i,1)
        rho(i)=rhos(i,1)
        rhop(i)=rhosp(i,1)
        rhopp(i)=rhospp(i,1)
      enddo
      do ispin=2,ispinmx
        do i=1,mmax
          rho(i)=rho(i)+rhos(i,ispin)
          rhop(i)=rhop(i)+rhosp(i,ispin)
          rhopp(i)=rhopp(i)+rhospp(i,ispin)
        enddo
      enddo

c meta gga
      ek_from_stat = fmom(0,mmax,al,1.d0,r,stat)
      if(tmgga .and. tnlc) then
        call dadv(mx,1,mmax,stat,stat_core,stat)
        ek_core_from_stat = fmom(0,mmax,al,1.d0,r,stat_core)
        ek_from_stat = ek_core_from_stat + ek_from_stat
        do i=1,mmax
          rho(i)=rho(i)+dc(i)
          rhop(i)=rhop(i)+dcp(i)
          rhopp(i)=rhopp(i)+dcpp(i)
        enddo
        open(11,file='alpha-ps.ekin_core')
        open(12,file='alpha-ps.s_eff')   ! effective scaled gradient
        open(13,file='alpha-ps.t_ratio') ! effective t_w/t_s
        do i=1,mmax
          write(11,'(e12.6,1x,e14.8)') r(i),stat(i)+1e-12
          vara = fx_xvar(rho(i),rhop(i),stat(i))
          write(12,'(e12.6,1x,e14.8)') r(i),vara+1e-12
          write(13,'(e12.6,1x,e14.8)')
     1      r(i),rhop(i)**2/( 8d0* rho(i)*stat(i) )+1e-12
        enddo
        write(11,*)'&'
        write(12,*)'&'
        write(13,*)'&'
        do i=1,mmax
          write(11,'(e12.6,1x,e14.8)') r(i),stat(i)-stat_core(i)+1e-12
          vara = rho(i) - dc(i)
          varb = rhop(i) - dcp(i)
          varc = stat(i) - stat_core(i)
          vard = fx_xvar(vara,varb,varc)
          write(12,'(e12.6,1x,e14.8)') r(i),vard+1e-12
          write(13,'(e12.6,1x,e14.8)') r(i),(rhop(i)-dcp(i))**2/
     1      ( 8d0* (rho(i)-dc(i)) * (stat(i)-stat_core(i)) )+1e-12
        enddo
        write(11,*)'&'
        write(12,*)'&'
        write(13,*)'&'
        do i=1,mmax
          write(11,'(e12.6,1x,e14.8)') r(i),stat_core(i)+1e-12
          vara = fx_xvar(dc(i),dcp(i),stat_core(i))
          write(12,'(e12.6,1x,e14.8)') r(i),vara+1e-12
          write(13,'(e12.6,1x,e14.8)') r(i),
     1       dcp(i)**2/( 8d0* dc(i)*stat_core(i) )+1e-12
        enddo
        close(11)
        close(12)
        close(13)
        do i=1,mmax
          rho(i)=rho(i)-dc(i)
          rhop(i)=rhop(i)-dcp(i)
          rhopp(i)=rhopp(i)-dcpp(i)
        enddo
      endif

c total charges
      tc_val=fmom(0,mmax,al,1.d0,r,rho)
      if(tnlc) then
        tc_core=fmom(0,mmax,al,1.d0,r,dc)
        if(igr .eq. 1) then
          t1c=-fmom(1,mmax,al,tc_core,r,dcp)/3.d0
          t2c=fmom(2,mmax,al,tc_core,r,dcpp)/12.d0
          if(tmgga) then
            do ir=1,mmax
              vvo(ir) = 0.125*dcp(ir)**2/max(1.d-10,dc(ir))
            enddo
            t3c=fmom(0,mmax,al,1.d0,r,vvo)
          endif
        endif
      endif

c total energy components
c hartree energy
      call vestat(mmax,cval,eeel,r,rho,ves,.true.)

c xc energy
      if(tnlc) then
        if(ispinmx.gt.1) then
          do i=1,mmax
            dc(i)=0.5d0*dc(i)
            dcp(i)=0.5d0*dcp(i)
            dcpp(i)=0.5d0*dcpp(i)
          enddo
        endif
        do ispin=1,ispinmx
          do i=1,mmax
            rhos(i,ispin)=rhos(i,ispin)+dc(i)
            rhosp(i,ispin)=rhosp(i,ispin)+dcp(i)
            rhospp(i,ispin)=rhospp(i,ispin)+dcpp(i)
          enddo
        enddo
      endif
      if(ispinmx.eq.1) then
        call vexcor(iexc,mmax,r,rhos(1,1),rhosp(1,1),rhospp(1,1),
     1              vxc(1,1),eexc,ex,ec,.true.)
      else
        call vexcos(iexcs,mmax,mmax,r,rhos,rhosp,rhospp,vxc,
     1              eexc,ex,ec,.true.)
      endif
      if(tnlc) then
        do ispin=1,ispinmx
          do i=1,mmax
            rhos(i,ispin)=rhos(i,ispin)-dc(i)
            rhosp(i,ispin)=rhosp(i,ispin)-dcp(i)
            rhospp(i,ispin)=rhospp(i,ispin)-dcpp(i)
          enddo
        enddo
        if(ispinmx.gt.1) then
          do i=1,mmax
            dc(i)=2.d0*dc(i)
            dcp(i)=2.d0*dcp(i)
            dcpp(i)=2.d0*dcpp(i)
          enddo
        endif
      endif
c xc potential energy
      evxc=dmelm(mmax,al,r,vxc(1,1),rhos(1,1))
     1    +dmelm(mmax,al,r,vxc(1,2),rhos(1,2))
c valence xc energy
      vexc=dmelm(mmax,al,r,dexc,rho)

      if(tkli) then
        ex=0.d0
        ex_roks=0.d0
        do i=1,norb
         ex=ex+f(i)*svm(i)
         ex_roks=ex_roks+f(i)*svm_roks(i)
        enddo
        ex=0.5d0*ex
        ex_roks=0.5d0*ex_roks
c       vi holds the hartree + xc potential, vxc the correlation potential
        evxc=dmelm(mmax,al,r,vi,rho)+dmelm(mmax,al,r,vxc,rho)-eeel
        vexc=ex+dmelm(mmax,al,r,dexc,rho)
      endif
      cexc=ex+ec-vexc

c ionic pseudopotential energy 
      evps=0.d0
      do i=1,norb
        if(f(i) .gt. 0.0) then
          ep(i)=gltfmv(mmax,al,r,ups(1,i),vorb(1,i),ups(1,i))
          evps=evps+f(i)*ep(i)
        endif
      enddo
c local pseudopotential energy
      evps_loc=dmelm(mmax,al,r,vbare(1,ll_loc),rho)
c screened pseudopotential energy
      epsp=evps
      do ispin=1,ispinmx
        epsp=epsp+dmelm(mmax,al,r,vee(1,ispin),rhos(1,ispin))
      enddo
c kinetic energy from eigenvalues
      ekin=dspv(ms,1,norb,f,e)-epsp
      etot=ekin+.5*eeel+evps+ex+ec

      call labelmap(int(zfull),symz,iexc,symxc)
      write(iu,'(a30,2x,a8)')   'chemical symbol', symz
      write(iu,'(a30,2x,f5.2)') 'nuclear charge', zfull
      write(iu,'(a30,2x,f5.2)') 'number of valence electrons',cval
      write(iu,'(a30,2x,i2)')   'number of valence states', nv
      write(iu,'(a30,2x,i2,2x,a40)')
     &    'exchange-correlation model', iexc,symxc
      if(tspin) write(iu,'(a30)')'spin-polarized calculation'
      if(tnlc) write(iu,'(a30)') 'nonlinear core-valence XC'
      write(iu,'(a30,2x,i4,f12.6,2x,e12.6)')
     &   'parameters radial mesh',mmax,amesh,r(1)
      call labels(1,llmx-1,1,sn,sl,sm)
      write(iu,'(a30,3x,a1)') 'input pseudopotentials up to',sl
      if(tcut_global)
     &    write(iu,'(a30,1x,f8.3)') 'global cutoff radius',rcut_global
      
      write(iu,620)
  619 format(/'fhi pseudopotential tool pslp - version ',a10,/)
  620 format(/10x,'=== pseudo atom (Hartree a.u.) ===',//
     &  '<        n     l   occupation  eigenvalue(eV)  ',
     &  'potential energy')
      do i=1,norb
        if(ispinmx.gt.1) then
          if(m(i).eq.1) then
            write(iu,631) i,n(i),l(i),f(i),e(i)*ry2,ep(i)
          else
            write(iu,632) i,n(i),l(i),f(i),e(i)*ry2,ep(i)
          endif
        else
            write(iu,630) i,n(i),l(i),f(i),e(i)*ry2,ep(i)
        endif
      enddo
  630 format('< ',i2,4x,2(i2,4x),f8.4,2x,f12.4,4x,f12.5)
  631 format('< ',i2,4x,i2,'_u',2x,i2,4x,f8.4,2x,f12.4,4x,f12.5)
  632 format('< ',i2,4x,i2,'_d',2x,i2,4x,f8.4,2x,f12.4,4x,f12.5)

  608 format(a30,2x,f12.5)
  610 format(a30,2x,f12.5,2x,f12.5)
      write(iu,*) 
      if(tkli) then
        write(iu,610) 'total energy [rks,roks]',etot,etot-ex+ex_roks
      else
        write(iu,608) 'total energy',etot
      endif
      write(iu,608) 'kinetic energy',ekin
      write(iu,608) 'ionic pseudopotential energy',evps
      write(iu,608) 'hartree energy',0.5*eeel
      if(tkli) then
        write(iu,610) 'xc energy [rks,roks]',ex+ec,ex_roks+ec
        write(iu,608) ' c energy           ',ec
      else
        write(iu,608) 'xc energy',ex+ec
      endif
      write(iu,608) 'local potential energy',evps_loc
      write(iu,608) 'xc potential energy',evxc
      if(tmgga) then
        write(iu,608) 'g kinetic energy',ek_from_stat
      endif
      if(tnlc) then
        write(iu,608) 'xc energy core',cexc
        write(iu,608) 'xc energy valence',vexc
        if(tmgga) then
          write(iu,608) 'g kinetic energy core',ek_core_from_stat
          write(iu,608) 'g kinetic energy valence',
     &                   ek_from_stat-ek_core_from_stat
        endif
      endif
      write(iu,608) 'integrated valence density', tc_val
      if(tnlc) then
        write(iu,608) 'integrated core density', tc_core
        if(igr.eq.1) then
          write(iu,608) ' ... 1st derivative test',t1c
          write(iu,608) ' ... 2nd derivative test',t2c
          if(tmgga) then
            write(iu,608) ' ... kinetic energy test',t3c
          endif
        endif
        do i=nin-10,1,-1
          if(rho(i) .le. dc(i)) goto 590
        enddo
 590    write(iu,608) 'estimated equidensity radius >',r(i+1)
      endif
      write(iu,'(a30,2x,i12,2x,a12,1pe9.1)')
     &  'number of iterations', it, 'convergence', de

c for plot x y range
      vl=1.d20
      vh=-1.d20
      do ll=1,llmx
        call dextv(mx,1,mmax,vbare(1,ll),bl,bh)
        vl=min(bl,vl)
        vh=max(bh,vh)
      enddo
      i=int(vl-int(vl/5)*5)-1+int(vl/5)*5
      j=int(vh-int(vh/5)*5)+1+int(vh/5)*5
      ll=max(1,(j-i)/4)
      write(iu,637) 'y range plot',i,j,ll
  637 format(a30,6x,3i4)

c spin polarized calculation makes sense up to here only, so stop
      if(tspin) then
        write(iu,'(/a)') 'pslp - spin-polarized pseudoatom done'
        stop 
      endif
     
c manipulate and output pseudopotential
      do ll=1,llmx
        ntl(ll)=0
        do i=1,norb
          if(n(i) .eq. ll) ntl(ll)=i
        enddo
c pseudopotential output with calculated wavefunctions
        if(ntl(ll) .gt. 0) then
          call dcpv(mx,1,mmax,ups(1,ntl(ll)),uout(1,ll))
        else
          call dnuv(mx,1,mmax,0.d0,uout(1,ll))
        endif
c screened pseudopotentials
        call dadv(mx,1,mmax,vbare(1,ll),vi,vorb(1,ll))

        do ir=1,mmax
          rxx(ir)=0.d0
        enddo
      enddo

c find radius outside of which pseudopotential's tail is coulomb like
      epstail=1.d-3
      do ir=1,mmax
        vvo(ir)=-cval/r(ir)
      enddo
      do ll=1,llmx
        rc(ll)=0.d0
        do ir=mmax,1,-1
          if(abs(vbare(ir,ll)-vvo(ir)).gt.epstail) then
            rc(ll)=r(ir)
            exit
          endif
        enddo
      enddo

      if(tcut_global) then
        write(ie,'(/,a,/,a)') 
     1    ' %pslp: WARNING - the output pseudopotential corresponds' ,
     1    '        to the globally cutoff input potential!'
        call outpot(40,mx,mmax,llmx,cval,rc,r,uu,vbare,vorb)
      else
        call outpot(40,mx,mmax,llmx,cval,rc,r,uout,vbare,vorb)
      endif
      if(tnlc) call outcore(27,mmax,1,r,dc,dcp,dcpp)

c radial pseudo-wavefunctions [the u(r)]
      do i=1,nv
        ninu(i)=nin
      enddo
      call out38(mx,1,nv,ninu,n,l,r,ups)

c informal stuff that is under construction
      if(tmgga) then
        if(tnlc) then
          do ir=1,mmax
            rho(ir) = rho(ir) + dc(ir)
            rhop(ir) = rhop(ir) + dcp(ir)
            rhopp(ir) = rhopp(ir) + dcpp(ir)
          enddo
        endif

        write(iu,'(/,3x,a)') 
     &                   '----- under construction ... begin -------'

        call vexcor(6,mmax,r,rho,rhop,rhopp,vxc,eexc,exv,ecv,.true.)
        write(iu,608) 'pbe post total energy',etot-ex-ec+exv+ecv
        call vexcor(16,mmax,r,rho,rhop,rhopp,vxc,eexc,exv,ecv,.true.)
        write(iu,608) 'mgga post total energy',etot-ex-ec+exv+ecv
     
        call vexcor(iexc,mmax,r,rho,rhop,rhopp,vxc,eexc,exv,ecv,.true.)
        write(iu,608) 'valence xc energy',exv+ecv
        write(iu,608) 'total linearized xc energy',epcv+exv+ecv
        write(iu,608) 'post linearized total energy',
     &    etot-ex-ec+epcv+exv+ecv
        if(tnlc) then
          do ir=1,mmax
            rho(ir) = rho(ir) - dc(ir)
            rhop(ir) = rhop(ir) - dcp(ir)
            rhopp(ir) = rhopp(ir) - dcpp(ir)
          enddo
        endif
        write(iu,'(3x,a)') '----- ... end ----------------------------'
      endif

      write(iu,*) 
      write(iu,*) 'pslp - pseudoatom done - now testing'

      if(.not. tlgd .and. .not. tkb) stop 'pslp - pseudoatom done'

c logarithmic derivatives and ghost state test
c read all-electron potential
      if(tlgd) then
        call dnuv(mx,1,mmax,0.d0,vae)
        if(irl .eq. 1) then
          write(iu,638) 
        else if( irl .eq. 2) then
          write(iu,639) 
        endif
        terr=.true.
        read(37,*,end=50,err=50) xxx,mmaxtmp,iexcae,irlae
        if(iexc .ne. iexcae) 
     &    write(ie,*)'& pslp - XC-type mismatch - using IEXC', iexc
        if(irlae .ne. irl) 
     &    write(ie,*)'& pslp - Relativity type mismatch - using IRL',irl
        do i=1,mmaxtmp
          read(37,*,end=48,err=48) rxx(i),vae(i)
        enddo
        terr=.false.
   48   if(i .le. mmaxtmp) terr=.true.
        if( abs(amesh-rxx(2)/rxx(1)) .gt. 5e-6 )
     &    write(ie,*)
     &      '& pslp - warning: grid from unit fort.37 incompatible'
   50   if(terr) then
          write(ie,*) 
     &      '& pslp - warning: bad/missing full potential file fort.37'
        endif
      endif
  638 format(/' --- assuming scalar-relativistic all-electron atom ---')
  639 format(/' --- assuming nonrelativistic all-electron atom ---')

c input or calculated wavefunctions for kb projectors
      call labels(1,l_loc,1,sn,sl,sm)
      write(iu,645) sl
      if(tkb) then
        if(tiwf) then 
          write(iu,641)
        else 
          write(iu,643)
        endif 
      endif
  641 format(' --- input wavefunctions used for kb potentials ---')
  643 format(' --- calculated wavefunctions used for kb potentials ---')
  645 format(/' --- ',a1,' component taken as local potential ---') 

      do ll=1,llmx
        if(.not. tiwf) call dcpv(mx,1,mmax,ups(1,ntl(ll)),uu(1,ll))
        ep(ll)=e(ntl(ll))
      enddo

c diagnostic radius
      if(rld .le. 0.0) rld=rcovalent(int(zfull))*1.3

      call ppcheck(iu,tnrl,tlgd,tkb,l_loc,lmax,lbeg,lend,mmax,rld,ep,r
     &,  vae,vi,uu(1,1),vbare(1,1))

c reciprocal space analysis (occupied states)
      write(iu,652)
 652  format(/' --- kinetic energy convergence in momentum space ---',//
     & 5x,'l  n  bracket   cutoff    norm   kinet. energy',/
     & 12x,'(eV)      (Ry)               (Hartree)')

      do ll=llbeg,llend
        neff=ll
        do i=1,nv
          if(l(i) .eq. ll-1 .and. f(i) .gt. 0.0) then
            call dadv(mx,1,mmax,vi,vbare(1,ll),vsl)
            call kinkon(iu,mmax,200.d0,0.05d0,neff,ll-1,e(i),r,vsl)
            neff=neff+1
          endif
        enddo
      enddo
c
      write(iu,'(1x,a)') '--- coulomb tail of pseudopotentials ---'
      write(iu,'(5x,a,1p,e8.1,a)') 'Tolerance',epstail,' is met for'
      do ll=1,llmx
       write(iu,'(5x,a,i2,a,f8.3)') 'l=',ll,' at radii >',rc(ll)
      enddo

      write(iu,'(/,a)') ' --- done & exiting ---'
c
c close file
      if(tkli) close(80)
c            
      end
c
