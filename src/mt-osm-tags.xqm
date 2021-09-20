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



(: TagsMISSk :)

declare function mt:TagsMISSkv($alpha,$O1,$O2,$alphap,$delta,$epsilon)
{
   if (count($O1 intersect $O2) >= $delta)
   then 
   ($alphap=$alpha or 
   count(
   for $ep in ($O1 intersect $O2)
   where $ep/tag[@k=$alphap]
   return $ep) <= $epsilon)
   else true()
};
 

declare function mt:TagsMISSkvTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (
for $beta in $O1/tag[@k=$key]/@v
let $i2 := function($x){some $z in $x/tag satisfies ($z/@v=$beta)}
let $O2 := mt:M($map,"*",$i2)
for $alphap in distinct-values(($O1 intersect $O2)/tag/@k)
where not($alphap=$key) 
return
if (not(mt:TagsMISSkv($key,$O1,$O2,$alphap,$epsilon,$delta)))
then $beta/../..[not(tag/@k=$alphap)])
return
if (empty($result)) then
mt:TagsMISSkvTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else  <test key="{$key}">{$result}</test>  

}; 

declare function mt:TagsMISSkvTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsMISSkvTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsMISSkvTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};



(: TagsCOMPkvk :)

declare function mt:TagsCOMPkvk($alpha,$O1,$O2,$O3,$delta,$epsilon)
{
   if (count($O1 intersect $O2) >= $delta)
   then 
   count($O1 intersect $O2 intersect $O3)>=$epsilon
   else true()
};
 


declare function mt:TagsCOMPkvkTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (
for $beta in $O1/tag[@k=$key]/@v
let $i2 := function($x){some $z in $x/tag satisfies ($z/@v=$beta)}
let $O2 := mt:M($map,"*",$i2)
for $alphap in $beta/../../tag/@k
where not($alphap=$key)
let $i3 := function($x){some $z in $x/tag satisfies ($z/@k=$alphap)}
let $O3 := mt:M($map,"*",$i3)
return
if (not(mt:TagsCOMPkvk($key,$O1,$O2,$O3,$epsilon,$delta)))
then $beta/../..)
return
if (empty($result)) then
mt:TagsCOMPkvkTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else  <test key="{$key}">{$result}</test>  

}; 

declare function mt:TagsCOMPkvkTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsCOMPkvkTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsCOMPkvkTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};



(: TagsCOMPkk :)

declare function mt:TagsCOMPkk($O1,$O2,$delta)
{
   count($O1 intersect $O2)>=$delta
};


declare function mt:TagsCOMPkkTest($map,$key,$delta,$rec)
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
if (not(mt:TagsCOMPkk($O1,$O2,$delta)))
then $beta/../..)
return
if (empty($result)) then
mt:TagsCOMPkkTestList($map,$O1/tag/@k,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else <test key="{$key}">{$result}</test>
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
  where count($O2 intersect $O3)<=$epsilon
  return ($O2 intersect $O3)
};


declare function mt:TagsNameTest($map,$beta,$delta,$epsilon)
{
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@v=$beta]}
let $O1 := mt:M($map,"*",$i1)
let $i2 := function($x){$x[some $z in ./tag satisfies contains(lower-case($z[@k="name"]/@v),lower-case($beta))]}
let $O2 := mt:M($map,"*",$i2)
return mt:TagsName($map,$O1,$O2,$beta,$delta,$epsilon)
}; 





 