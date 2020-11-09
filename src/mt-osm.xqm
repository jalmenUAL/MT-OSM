module namespace mt = 'mt';


(: M :)

declare function mt:M($map,$type,$cond)
{
  filter($map/osm/*,function($e){mt:type($e,$type) and $cond($e)})
};

(: Node :)

declare function mt:Node($map,$nd)
{
  let $ref := data($nd/@ref)
  return $map/osm/node[@id=$ref]
};

(: Lat :)

declare function mt:Lat($nd)
{
  data($nd/@lat)
};

(: Lon :)

declare function mt:Lon($nd)
{
  data($nd/@lon)
};

(: type :)

declare function mt:type($e,$type)
{
  if ($type="*") then name($e)="node" or name($e)="way"
  else if ($type="node") then name($e)="node"
  else name($e)="way"
};

(: TagsCOMPkv :)
 



declare function mt:TagsCOMPkv($alpha,$beta,$O1,$O2,$delta,$epsilon)
{
   if (count($O1 intersect $O2) >= $delta)
   then
   every $alphap in $O2/tag[@v=$beta]/@k 
   satisfies
   ($alpha=$alphap)
   or 
   count(
   for $e2 in $O2
   where
    $e2/tag[@k=$alphap and @v=$beta]
    and
     not(string(number($beta)) != 'NaN') and
       not($beta="yes") and
       not($beta="no")  
   return $e2) <= $epsilon
   else true()
};
 

(: TagsCOMPkvTest :)

declare function mt:TagsCOMPkvTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (
for $beta in $O1/tag[@k=$key]/@v
let $i2 := function($x){some $z in $x/tag satisfies ($z/@v=$beta)}
let $O2 := mt:M($map,"*",$i2)
return
if (not(mt:TagsCOMPkv($key,$beta,$O1,$O2,$epsilon,$delta)))
then $beta/../..)
return
if (empty($result)) then
mt:TagsCOMPkvTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else $result
}; 

declare function mt:TagsCOMPkvTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsCOMPkvTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsCOMPkvTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};


(: TagsCOMPkk :)

declare function mt:TagsCOMPkk($O1,$O2,$epsilon)
{
   count($O1 intersect $O2)>=$epsilon
};

(: TagsCOMPkkTest :)

declare function mt:TagsCOMPkkTest($map,$key,$epsilon,$rec)
{  
if ($rec/k=$key) then ()
else
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@k=$key]}
let $O1 := mt:M($map,"*",$i1)
let $result :=
(for $beta in $O1/tag/@k
let $i2 := function($x){$x[some $z in ./tag satisfies $z/@k=$beta]}
let $O2 := mt:M($map,"*",$i2)
return
if (not(mt:TagsCOMPkk($O1,$O2,$epsilon)))
then $beta/../..)
return
if (empty($result)) then
mt:TagsCOMPkkTestList($map,$O1/tag/@k,$epsilon,<list>{$rec/*,<k>{$key}</k>}</list>)
else $result
}; 

declare function mt:TagsCOMPkkTestList($map,$list,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsCOMPkkTest($map,data(head($list)),$delta,$rec)
  return
  if (empty($result)) then mt:TagsCOMPkkTestList($map,tail($list),$delta,$rec)
  else $result
};

(: TagsName :)

declare function mt:TagsName($map,$O1,$O2,$beta,$delta,$epsilon)
{
  if (count($O1)>=$delta) then
  let $i3 := function($x){$x[every $z in ./tag satisfies not($z/@v=$beta)]}
  let $O3 := mt:M($map,"*",$i3)
  where count($O2 intersect $O3)>=$epsilon
  return ($O2 intersect $O3)
};

(: TagsNameTest :)

declare function mt:TagsNameTest($map,$beta,$delta,$epsilon)
{
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@v=$beta]}
let $O1 := mt:M($map,"*",$i1)
let $i2 := function($x){$x[some $z in ./tag satisfies contains(lower-case($z[@k="name"]/@v),lower-case($beta))]}
let $O2 := mt:M($map,"*",$i2)
return mt:TagsName($map,$O1,$O2,$beta,$delta,$epsilon)
}; 

(: NoDeadlock :)

declare function mt:NoDeadlock($O1,$O2)
{
  every $w1 in $O1 
  satisfies
  every $w2 in $O1
      satisfies 
      $w1/@id=$w2/@id 
      or
      not($w1/nd[last()]/@ref = $w2/nd[last()]/@ref)
      or
      ($w1/nd[last()]/@ref = $w2/nd[last()]/@ref
      and 
      (some $w in $O2
      satisfies  
      ($w/nd/@ref = $w1/nd[last()]/@ref
      and not($w1/nd[last()]/@ref=$w/nd[last()]/@ref))))
};

(: NoDeadlockTest :)

declare function mt:NoDeadlockTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
              and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]  
              and (some $z in $x/tag satisfies $z[@k="highway"])})
  return if (not(mt:NoDeadlock($O1,$O2)))
  then
  $O1
  else
  mt:NoDeadlockTestList($map,$O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
  
};

declare function mt:NoDeadlockTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:NoDeadlockTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:NoDeadlockTestList($map,tail($list),$rec)
  else $result
};


(: NoIsolatedWay :)

declare function mt:NoIsolatedWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies 
  some $n in $w1/nd
  satisfies 
  some $m in $w2/nd
  satisfies    
  $n/@ref=$m/@ref
};

(: NoIsolatedWayTest :)

declare function mt:NoIsolatedWayTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(mt:NoIsolatedWay($O1,$O2))) then
  $O1
  else 
  mt:NoIsolatedWayTestList($map,$O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function mt:NoIsolatedWayTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:NoIsolatedWayTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:NoIsolatedWayTestList($map,tail($list),$rec)
  else $result
};

(: ExitWay :)

declare function mt:ExitWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies
  some $n in $w1/nd
  satisfies
  some $m in $w2/nd
  satisfies
  ($n/@ref=$m/@ref
  and not($w2/nd[last()]/@ref=$m/@ref))
   
};

(: ExitWayTest :)

declare function mt:ExitWayTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(mt:ExitWay($O1,$O2))) then
  $O1
  else 
  mt:ExitWayTestList($map,$O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{data($name)}</n>}</list>)
};

declare function mt:ExitWayTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:ExitWayTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:ExitWayTestList($map,tail($list),$rec)
  else $result
};

(: EntranceWay :)

declare function mt:EntranceWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies
  some $n in $w1/nd 
  satisfies
  some $m in $w2/nd
  satisfies
  ($n/@ref=$m/@ref
  and not($w2/nd[1]/@ref=$m/@ref))
   
};

(: EntranceWayTest :)

declare function mt:EntranceWayTest($map,$name,$rec)

{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(mt:EntranceWay($O1,$O2))) then
  $O1
  else 
  mt:EntranceWayTestList($map,$O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function mt:EntranceWayTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:EntranceWayTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:EntranceWayTestList($map,tail($list),$rec)
  else $result
};

(: ExitRAbout :)

declare function mt:ExitRAbout($O1,$O2)
{
  some $w1 in $O1
  satisfies
  (some $w2 in $O1[not((some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"]))] union $O2
  satisfies  
  some $n in $w1/nd
  satisfies
  $w2/nd[1]/@ref=$n/@ref)
  
   
};

(: ExitRAboutTest :)

declare function mt:ExitRAboutTest($map,$name,$rec)

{
  if ($rec/n=$name) then ()
  else
 let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"]) and (some $z in $x/tag satisfies $z[@k="junction" and @v="roundabout"])}) 
  let $O2 :=  mt:M($map,"way",function($x){(some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]
  and (some $z in $x/tag satisfies $z[@k="highway"]))})
  return
  if (not(empty($O1)) and (not(mt:ExitRAbout($O1,$O2)))) then
  $O1
  else  
  mt:ExitRAboutTestList($map,$O2[
  (some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function mt:ExitRAboutTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:ExitRAboutTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:ExitRAboutTestList($map,tail($list),$rec)
  else $result
};

(: EntRAbout :)

declare function mt:EntRAbout($O1,$O2)
{
  some $w1 in $O1
  satisfies
  (some $w2 in $O1[not(some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])] union $O2
  satisfies
  some $n in $w1/nd 
  satisfies
  $w2/nd[last()]/@ref=$n/@ref)
  
};

(: EntRAboutTest :)

declare function mt:EntRAboutTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])  and (some $z in $x/tag satisfies $z[@k="junction" and @v="roundabout"])})  
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)
and (some $z in $x/tag satisfies $z[@k="highway"])]})
  return
  if  (not(empty($O1)) and (not(mt:EntRAbout($O1,$O2)))) then
  $O1
  else 
  mt:EntRAboutTestList($map,$O2[  
(some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function mt:EntRAboutTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:EntRAboutTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:EntRAboutTestList($map,tail($list),$rec)
  else $result
};

(: Connected :)

declare function mt:Connected($O1,$O2)
{
  every $w1 in $O1
  satisfies
  (
  some $w in $O1 union $O2
  satisfies
  (not($w/@id=$w1/@id)
  and
  (some $n in $w/nd satisfies
  ($w1/nd[last()])/@ref=$n/@ref))
  )
};

(: ConnectedTest :)

declare function mt:ConnectedTest($map,$name,$rec)
{
 if ($rec/n=$name) then ()
  else 
 let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"]) and not(some $z in $x/tag satisfies $z[@k="noexit" and @v="yes"])})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and 
  (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(empty($O1)) and(not(mt:Connected($O1,$O2)))) then
  $O1
  else  
  mt:ConnectedTestList($map,$O2[not(some $z in ./tag satisfies $z[@k="noexit" and @v="yes"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function mt:ConnectedTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:ConnectedTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:ConnectedTestList($map,tail($list),$rec)
  else $result
};

(: memberLine: node-nodes :)

declare function mt:memberLine($x,$n1,$n2)
{
  mt:memberLineP(mt:Lat($x),mt:Lon($x),mt:Lat($n1),mt:Lon($n1),mt:Lat($n2),mt:Lon($n2))
  
};

(: memberLineP: points-points :)

declare function mt:memberLineP($x,$y,$x1,$y1,$x2,$y2)
{
  
  if ((($y - $y1) * ($x2 - $x1)) - (($y2 - $y1) * ($x - $x1)) =0 )
  then true()
  else false()
  
};

(: overlapLine: nodes-nodes :)

declare function mt:overlapLine($n1,$n2,$n3,$n4)
{
    mt:memberLine($n1,$n3,$n4) and mt:memberLine($n2,$n3,$n4)

};

(: intersectionLine: nodes-nodes :)

declare function mt:intersectionLine($n1,$n2,$n3,$n4)
{
  mt:intersectionLineP(mt:Lat($n1),mt:Lon($n1),mt:Lat($n2),
  mt:Lon($n2),mt:Lat($n3),mt:Lon($n3),mt:Lat($n4),mt:Lon($n4))
  
};

(: intersectionLine points-points :)

declare function mt:intersectionLineP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
{
  
 if (((($x1 - $x2) * ($y3 - $y4)) - (($y1 - $y2) * ($x3 - $x4)))=0)
 then ()
 else 
 let $t := 
     ((($x1 - $x3)*($y3 - $y4)) - (($y1 - $y3)*($x3 - $x4)))
     div 
     ((($x1 - $x2)*($y3 - $y4)) - (($y1 - $y2)*($x3 - $x4)))
 return ($x1 + $t*($x2 - $x1), $y1 + $t*($y2 - $y1))
  
};



(: memberSegment: node-nodes :)

declare function mt:memberSegment($n,$n1,$n2)
{
  mt:memberSegmentP(mt:Lat($n),mt:Lon($n),mt:Lat($n1),mt:Lon($n1),mt:Lat($n2),mt:Lon($n2))
  
};

(: memberSegmentPoint: points-nodes :)

declare function mt:memberSegmentPoint($x1,$x2,$n1,$n2)
{
  mt:memberSegmentP($x1,$x2,mt:Lat($n1),mt:Lon($n1),mt:Lat($n2),mt:Lon($n2))
  
};

(: memberSegmentP: point-points :)

declare function mt:memberSegmentP($x,$y,$x1,$y1,$x2,$y2)
{  
  if 
  (
  (math:sqrt(math:pow($x - $x1,2) + math:pow($y - $y1,2)) +
  math:sqrt(math:pow($x - $x2,2) + math:pow($y - $y2,2))) -
  math:sqrt(math:pow($x1 - $x2,2) + math:pow($y1 - $y2,2)) <= 0
  )
  then true()
  else false()
  
  
};

(: overlapSegment: nodes-nodes :)

declare function mt:overlapSegment($n1,$n2,$n3,$n4)
{
   
mt:overlapLine($n1,$n2,$n3,$n4) and 
       (mt:memberSegment($n1,$n3,$n4) or mt:memberSegment($n2,$n3,$n4))


};

(: intersectionSegment: nodes-nodes :)

declare function mt:intersectionSegment($n1,$n2,$n3,$n4)
{
  mt:intersectionSegmentP(mt:Lat($n1),mt:Lon($n1),mt:Lat($n2),mt:Lon($n2),mt:Lat($n3),mt:Lon($n3),mt:Lat($n4),mt:Lon($n4))
  
};




(: intersectionSegment: points-points :)

declare function mt:intersectionSegmentP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
{
  let $s := mt:intersectionLineP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
  return 
  if (empty($s)) then ()
  else
  if (mt:memberSegmentP($s[1],$s[2],$x1,$y1,$x2,$y2)) then $s
  else ()
  
};


(: AreaNoInt :)


declare function mt:AreaNoInt($map,$O1,$O2)
{
  every $w1 in $O1
  satisfies
  every $w2 in $O2
  satisfies  
  $w2/tag/@k="highway"
  or
  $w2/tag/@k="waterway"
  or
  $w2/tag/@k="railway"
  or
  (every $n2 in $w1/nd
   satisfies
   every $n2p in $w2/nd
   satisfies
   let $n1 := ($n2/preceding-sibling::node())[last()]
   let $n1p := ($n2p/preceding-sibling::node())[last()] 
   let $p := mt:intersectionLine(mt:Node($map,$n1),mt:Node($map,$n2),mt:Node($map,$n1p),mt:Node($map,$n2p))
   return 
   (mt:memberLine(mt:Node($map,$n1),mt:Node($map,$n1p),mt:Node($map,$n2p))
   and
   mt:memberLine(mt:Node($map,$n2),mt:Node($map,$n1p),mt:Node($map,$n2p))
   ) 
   or
   empty($p)
   or
   (not(mt:memberSegmentPoint($p[1],$p[2],mt:Node($map,$n1),mt:Node($map,$n2))) 
    or 
    not(mt:memberSegmentPoint($p[1],$p[2],mt:Node($map,$n1p),mt:Node($map,$n2p)))
   )
   )
  
};

 

declare function mt:AreaNoIntTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
  and ((some $z in $x/tag satisfies $z[@k="area" and@v="yes"])
  or (some $z in $x/tag satisfies $z[@k="building"])
  or (some $z in $x/tag satisfies $z[@k="landuse"]))
  })
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]})
  return
  if (not(empty($O1)) and (not(mt:AreaNoInt($map,$O1,$O2)))) then $O1
  else mt:AreaNoIntTestList($map,$O2[(some $z in ./tag satisfies $z[@k="area" and@v="yes"])
  or (some $z in ./tag satisfies $z[@k="building"])
  or (some $z in ./tag satisfies $z[@k="landuse"])
  ]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function mt:AreaNoIntTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:AreaNoIntTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:AreaNoIntTestList($map,tail($list),$rec)
  else $result
};


declare function mt:NoOverlap($map,$O1,$O2)
{
  every $w1 in $O1
  satisfies
  every $w2 in $O2
  satisfies 
  (every $n2 in $w1/nd
  satisfies
  every $n2p in $w2/nd
  satisfies
  let $n1 := ($n2/preceding-sibling::node())[last()]
  let $n1p := ($n2p/preceding-sibling::node())[last()] 
  return
  not(mt:overlapSegment(mt:Node($map,$n1),mt:Node($map,$n2),mt:Node($map,$n1p),mt:Node($map,$n2p)))
  )
};

declare function mt:NoOverlapTest($map,$name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
  and (some $z in $x/tag  satisfies ($z/@k="building" or $z/@k="highway"))})
  let $O2 :=  mt:M($map,"way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]
  and (some $z in $x/tag  satisfies ($z/@k="building" or $z/@k="highway"))})
  return
  if (not(mt:NoOverlap($map,$O1,$O2))) then
  $O1
  else  
  mt:NoOverlapTestList($map,$O2/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function mt:NoOverlapTestList($map,$list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:NoOverlapTest($map,data(head($list)),$rec)
  return
  if (empty($result)) then mt:NoOverlapTestList($map,tail($list),$rec)
  else $result
};



 