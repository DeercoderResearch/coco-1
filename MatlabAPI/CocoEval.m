classdef CocoEval < handle
  % Interface for evaluating detection on the Microsoft COCO dataset.
  %
  % The usage for CocoEval is as follows:
  %  cocoGt=..., cocoDt=...       % load dataset and results
  %  E = CocoEval(cocoGt,cocoDt); % initialize CocoEval object
  %  E.params.recThrs = ...;      % set parameters as desired
  %  E.evaluate();                % run per image evaluation
  %  disp( E.evalImgs )           % inspect per image results
  %  E.accumulate();              % accumulate per image results
  %  disp( E.eval )               % inspect accumulated results
  %  E.summarize();               % display summary metrics of results
  % For example usage see evalDemo.m and http://mscoco.org/.
  %
  % The evaluation parameters are as follows (defaults in brackets):
  %  imgIds     - [all] N img ids to use for evaluation
  %  catIds     - [all] K cat ids to use for evaluation
  %  iouThrs    - [.5:.05:.95] T=10 IoU thresholds for evaluation
  %  recThrs    - [0:.01:1] R=101 recall thresholds for evaluation
  %  areaRng    - [...] A=4 object area ranges for evaluation
  %  maxDets    - [1 10 100] M=3 thresholds on max detections per image
  %  useSegm    - [1] if true evaluate against ground-truth segments
  %  useCats    - [1] if true use category labels for evaluation
  % Note: if useSegm=0 the evaluation is run on bounding boxes.
  % Note: if useCats=0 category labels are ignored as in proposal scoring.
  % Note: by default areaRng=[0 1e5; 0 32; 32 96; 96 1e5].^2. These A=4
  % settings correspond to all, small, medium, and large objects, resp.
  %
  % evaluate(): evaluates detections on every image and every category and
  % concats the results into the struct array "evalImgs" with fields:
  %  imgId      - results for the img with the given id
  %  catId      - results for the cat with the given id
  %  areaRng    - results for objects in the given areaRng
  %  maxDets    - results given the specified max number of detections
  %  dtIds      - [1xD] id for each of the D detections (dt)
  %  gtIds      - [1xG] id for each of the G ground truths (gt)
  %  dtMatches  - [TxD] matching gt id at each IoU or 0
  %  gtMatches  - [TxG] matching dt id at each IoU or 0
  %  dtScores   - [1xD] confidence of each dt
  %  gtIgnore   - [1xG] ignore flag for each gt
  %  dtIgnore   - [TxD] ignore flag for each dt at each IoU
  %  ious       - [DxG] iou between every dt and gt
  %
  % accumulate(): accumulates the per-image, per-category evaluation
  % results in "evalImgs" into the struct "eval" with fields:
  %  params     - parameters used for evaluation
  %  date       - date evaluation was performed
  %  counts     - [T,R,K,A,M] parameter dimensions (see above)
  %  precision  - [TxRxKxAxM] precision for every evaluation setting
  %  recall     - [TxKxAxM] max recall for every evaluation setting
  % Note: precision and recall==-1 for settings with no gt objects.
  %
  % See also CocoApi, MaskApi, cocoDemo, evalDemo
  %
  % Microsoft COCO Toolbox.      Version 1.0
  % Data, paper, and tutorials available at:  http://mscoco.org/
  % Code written by Piotr Dollar and Tsung-Yi Lin, 2015.
  % Licensed under the Simplified BSD License [see coco/license.txt]
  
  properties
    cocoGt      % ground truth COCO API
    cocoDt      % detections COCO API
    params      % evaluation parameters
    evalImgs    % per-image per-category evaluation results
    eval        % accumulated evaluation results
    stats       % evaluation summary statistics
  end
  
  methods
    function ev = CocoEval( cocoGt, cocoDt )
      % Initialize CocoEval using coco APIs for gt and dt.
      if(nargin>0), ev.cocoGt = cocoGt; end
      if(nargin>1), ev.cocoDt = cocoDt; end
      if(nargin>0), ev.params.imgIds = sort(ev.cocoGt.getImgIds()); end
      if(nargin>0), ev.params.catIds = sort(ev.cocoGt.getCatIds()); end
      ev.params.iouThrs = .5:.05:.95;
      ev.params.recThrs = 0:.01:1;
      ev.params.areaRng = [0 1e5; 0 32; 32 96; 96 1e5].^2;
      ev.params.maxDets = [1 10 100];
      ev.params.useSegm = 1;
      ev.params.useCats = 1;
    end
    
    function evaluate( ev )
      % Run per image evaluation on given images.
      fprintf('Running per image evaluation...      '); clk=clock;
      p=ev.params; if(~p.useCats), p.catIds=1; end
      p.imgIds=unique(p.imgIds); p.catIds=unique(p.catIds);
      ev.params=p; N=length(p.imgIds); K=length(p.catIds);
      A=size(p.areaRng,1); M=length(p.maxDets);
      [nGt,iGt]=getAnnCounts(ev.cocoGt,p.imgIds,p.catIds,p.useCats);
      [nDt,iDt]=getAnnCounts(ev.cocoDt,p.imgIds,p.catIds,p.useCats);
      [ks,is]=ndgrid(1:K,1:N); ev.evalImgs=cell(K*N,A,M);
      for i=1:K*N, if(nGt(i)==0 && nDt(i)==0), continue; end
        gt=ev.cocoGt.data.annotations(iGt(i):iGt(i)+nGt(i)-1);
        dt=ev.cocoDt.data.annotations(iDt(i):iDt(i)+nDt(i)-1);
        if( p.useSegm )
          im=ev.cocoGt.loadImgs(p.imgIds(is(i))); h=im.height; w=im.width;
          for g=1:nGt(i), s=gt(g).segmentation; if(~isstruct(s))
              gt(g).segmentation=MaskApi.frPoly(s,h,w); end; end
          f='segmentation'; if(isempty(dt)), [dt(:).(f)]=deal(); end
          if(~isfield(dt,f)), s=MaskApi.frBbox(cat(1,dt.bbox),h,w);
            for d=1:nDt(i), dt(d).(f)=s(d); end; end
        else
          f='bbox'; if(isempty(dt)), [dt(:).(f)]=deal(); end
          if(~isfield(dt,f)), s=MaskApi.toBbox([dt.segmentation]);
            for d=1:nDt(i), dt(d).(f)=s(d,:); end; end
        end
        q=p; q.catIds=p.catIds(ks(i)); q.imgIds=p.imgIds(is(i));
        for j=1:A, q.areaRng=p.areaRng(j,:);
          q.maxDets=max(p.maxDets); E0=CocoEval.evaluateImg(gt,dt,q);
          for k=1:M, E=E0; m=p.maxDets(k); E.maxDets=m; m=min(nDt(i),m);
            E.dtIds=E.dtIds(1:m); E.dtMatches=E.dtMatches(:,1:m);
            E.dtScores=E.dtScores(1:m); E.dtIgnore=E.dtIgnore(:,1:m);
            E.gtMatches=ismember(E.gtMatches,E.dtIds).*E.gtMatches;
            E.ious=E.ious(1:m,:); ev.evalImgs{i,j,k}=E;
          end
        end
      end
      ev.evalImgs=[ev.evalImgs{nGt>0|nDt>0,:,:}];
      fprintf('DONE (t=%0.2fs).\n',etime(clock,clk));
      
      function [ns,is] = getAnnCounts( coco, imgIds, catIds, useCats )
        % Return ann counts and indices for given imgIds and catIds.
        as=sort(coco.getCatIds()); [~,a]=ismember(coco.inds.annCatIds,as);
        bs=sort(coco.getImgIds()); [~,b]=ismember(coco.inds.annImgIds,bs);
        if(~useCats), a(:)=1; as=1; end; ns=zeros(length(as),length(bs));
        for ind=1:length(a), ns(a(ind),b(ind))=ns(a(ind),b(ind))+1; end
        is=reshape(cumsum([0 ns(1:end-1)])+1,size(ns));
        [~,a]=ismember(catIds,as); [~,b]=ismember(imgIds,bs);
        ns=ns(a,b); is=is(a,b);
      end
    end
    
    function accumulate( ev )
      % Accumulate per image evaluation results.
      fprintf('Accumulating evaluation results...   '); clk=clock;
      if(isempty(ev.evalImgs)), error('Please run evaluate() first'); end
      p=ev.params; T=length(p.iouThrs); R=length(p.recThrs);
      K=length(p.catIds); A=size(p.areaRng,1); M=length(p.maxDets);
      precision=-ones(T,R,K,A,M); recall=-ones(T,K,A,M); Es=ev.evalImgs;
      [~,k]=ismember([Es.catId]',p.catIds);
      [~,a]=ismember(cat(1,Es.areaRng),p.areaRng,'rows');
      [~,m]=ismember([Es.maxDets]',p.maxDets); ks=(m-1)*K*A+(a-1)*K+k;
      for k=1:K*A*M
        E=Es(ks==k); dtm=[E.dtMatches]; dtIg=[E.dtIgnore];
        np=nnz(~[E.gtIgnore]); if(np==0), continue; end
        [~,o]=sort([E.dtScores],'descend');
        tps=reshape( dtm & ~dtIg,T,[]); tps=tps(:,o);
        fps=reshape(~dtm & ~dtIg,T,[]); fps=fps(:,o);
        for t=1:T
          tp=cumsum(tps(t,:)); fp=cumsum(fps(t,:)); nd=length(tp);
          rc=tp/np; pr=tp./(fp+tp); q=zeros(1,R);
          if(nd), recall(t,k)=rc(end); else recall(t,k)=0; end
          for i=nd-1:-1:1, pr(i)=max(pr(i+1),pr(i)); end
          i=1; r=1; while(r<=R && i<=nd), if(rc(i)<p.recThrs(r))
              i=i+1; else q(r)=pr(i); r=r+1; end; end; precision(t,:,k)=q;
        end
      end
      ev.eval=struct('params',p,'date',date,'counts',[T R K A M],...
        'precision',precision,'recall',recall);
      fprintf('DONE (t=%0.2fs).\n',etime(clock,clk));
    end
    
    function summarize( ev )
      % Compute and display summary metrics for evaluation results.
      if(isempty(ev.eval)), error('Please run accumulate() first'); end
      ev.stats=zeros(1,9);
      ev.stats(1) = summarize1(1,':','all',100);
      ev.stats(2) = summarize1(1,.50,'all',100);
      ev.stats(3) = summarize1(1,.75,'all',100);
      ev.stats(4) = summarize1(1,':','small',100);
      ev.stats(5) = summarize1(1,':','medium',100);
      ev.stats(6) = summarize1(1,':','large',100);
      ev.stats(7) = summarize1(0,':','all',1);
      ev.stats(8) = summarize1(0,':','all',10);
      ev.stats(9) = summarize1(0,':','all',100);
      
      function s = summarize1( ap, iouThr, areaRng, maxDets )
        p=ev.params; i=iouThr; m=find(p.maxDets==maxDets);
        if(i~=':'), iStr=sprintf('%.2f     ',i); i=find(p.iouThrs==i);
        else iStr=sprintf('%.2f:%.2f',min(p.iouThrs),max(p.iouThrs)); end
        as=[0 1e5; 0 32; 32 96; 96 1e5].^2; a=find(areaRng(1)=='asml');
        a=find(p.areaRng(:,1)==as(a,1) & p.areaRng(:,2)==as(a,2));
        if(ap), tStr='Precision (AP)'; s=ev.eval.precision(i,:,:,a,m);
        else    tStr='Recall    (AR)'; s=ev.eval.recall(i,:,a,m); end
        fStr=' Average %s @[ IoU=%s | area=%6s | maxDets=%3i ] = %.3f\n';
        s=mean(s(s>=0)); fprintf(fStr,tStr,iStr,areaRng,maxDets,s);
      end
    end
  end
  
  methods( Static )
    function e = evaluateImg( gt, dt, params )
      % Run evaluation for a single image and category.
      p=params; T=length(p.iouThrs); aRng=p.areaRng;
      if(~isfield(gt,'ignore')), [gt(:).ignore]=deal(0); end
      a=[gt.area]; gtIg=[gt.iscrowd]|[gt.ignore]|a<aRng(1)|a>aRng(2);
      G=length(gt); D=length(dt); for g=1:G, gt(g).ignore=gtIg(g); end
      % sort dt highest score first, sort gt ignore last
      [~,o]=sort([gt.ignore],'ascend'); gt=gt(o);
      [~,o]=sort([dt.score],'descend'); dt=dt(o);
      if(D>p.maxDets), D=p.maxDets; dt=dt(1:D); end
      % compute iou between each dt and gt region
      iscrowd = uint8([gt.iscrowd]); t=p.useSegm;
      if(t), g=[gt.segmentation]; else g=cat(1,gt.bbox); end
      if(t), d=[dt.segmentation]; else d=cat(1,dt.bbox); end
      ious=MaskApi.iou(d,g,iscrowd);
      % attempt to match each (sorted) dt to each (sorted) gt
      gtm=zeros(T,G); gtIds=[gt.id]; gtIg=[gt.ignore];
      dtm=zeros(T,D); dtIds=[dt.id]; dtIg=zeros(T,D);
      for t=1:T
        for d=1:D
          % information about best match so far (m=0 -> unmatched)
          iou=min(p.iouThrs(t),1-1e-10); m=0;
          for g=1:G
            % if this gt already matched, and not a crowd, continue
            if( gtm(t,g)>0 && ~iscrowd(g) ), continue; end
            % if dt matched to reg gt, and on ignore gt, stop
            if( m>0 && gtIg(m)==0 && gtIg(g)==1 ), break; end
            % if match successful and best so far, store appropriately
            if( ious(d,g)>=iou ), iou=ious(d,g); m=g; end
          end
          % if match made store id of match for both dt and gt
          if(~m), continue; end; dtIg(t,d)=gtIg(m);
          dtm(t,d)=gtIds(m); gtm(t,m)=dtIds(d);
        end
      end
      % set unmatched detections outside of area range to ignore
      if(isempty(dt)), a=zeros(1,0); else a=[dt.area]; end
      dtIg = dtIg | (dtm==0 & repmat(a<aRng(1)|a>aRng(2),T,1));
      % store results for given image and category
      e = struct('imgId',p.imgIds,'catId',p.catIds,'areaRng',p.areaRng,...
        'maxDets',p.maxDets,'dtIds',dtIds,'gtIds',gtIds,...
        'dtMatches',dtm,'gtMatches',gtm,'dtScores',[dt.score],...
        'gtIgnore',gtIg,'dtIgnore',dtIg,'ious',ious);
    end
  end
end
