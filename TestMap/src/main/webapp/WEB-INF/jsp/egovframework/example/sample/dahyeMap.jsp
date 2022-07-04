<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c"      uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="form"   uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="ui"     uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ko" xml:lang="ko">
  <head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/openlayers/openlayers.github.io@master/en/v6.2.1/css/ol.css" type="text/css">
    <style>
      .map {
	  height: 870px;
	  width: 100%;
	}
	#marker {
		width: 20px;
		height: 20px;
		border: 1px solid #088;
		border-radius: 10px;
		background-color: #0FF;
		opacity: 0.5;
	}
	#vienna {
		text-decoration: none;
		color: white;
		font-size: 11pt;
		font-weight: bold;
		text-shadow: black 0.1em 0.1em 0.2em;
	}
	.popover-content {
		min-width: 180px;
	}
	select{
		text-align: center;
	}		
	h2{
		text-align: center;
	}
	.selectBox{
		margin:  0 20%;
	}
	body{
		margin: 0;
	}
</style>
<script src="https://cdn.jsdelivr.net/gh/openlayers/openlayers.github.io@master/en/v6.2.1/build/ol.js"></script>
<script src="http://code.jquery.com/jquery-latest.min.js"></script>
<script src="https://cdn.rawgit.com/openlayers/openlayers.github.io/master/en/v5.3.0/build/ol.js"></script>
<title>다혜지도</title>
</head>
<body>
	<h2>Dahye's Map</h2>    
	<button style="margin: 0 47%"><a href="javascript:fnChangeCenter();">되돌리기</a></button>
	<div>
		<!-- 브이월드 행정구역도를 이용한 셀렉트 박스 구현... 공간정보를 기반으로 하고 있어서 국가공간정보포털보다 느림 -->
		<form id="nsdiSearchForm" action="#" class="form_data" onsubmit="return false;search();">
			<select id="sido_code">
				<option>선택</option>
			</select>
			<select id="sigoon_code">
				<option>선택</option>
			</select>
			<select id="dong_code">
				<option>선택</option>
			</select>
			<select id="lee_code">
				<option>선택</option>
			</select>
		</form>
	</div>
    
    <div id="map" class="map"></div>
    
    <script type="text/javascript">
    
	//vworld api 사용, key=4F7654DB-A655-3075-8842-B2EFEB440741 (~22/9/23)
    var layer = new ol.layer.Tile({
    	title : 'Vworld Map', //이름
    	type : 'base', 
    	source: new ol.source.XYZ({ 
    		url : 'http://api.vworld.kr/req/wmts/1.0.0/4F7654DB-A655-3075-8842-B2EFEB440741/Base/{z}/{y}/{x}.png'
    	})
    });


    //map 초기화면 세팅
    var pos = ol.proj.fromLonLat(ol.proj.transform([14193235.07614238, 4328176.075298277], 'EPSG:3857', 'EPSG:4326'));
    var map = new ol.Map({
    	layers: [layer],
    	target: 'map',
    	view: new ol.View({
    		center: pos,
    		zoom: 8,
    	}),
    });

    // 팝업창 오버레이
    var popup = new ol.Overlay({
    	element: document.getElementById('popup'),
    });
    map.addOverlay(popup);

    //클릭 이벤트 설정
    map.on('click', function(evt) {			
    	var element = popup.getElement();
    	var coordinate = evt.coordinate;
    	var pos = ol.proj.fromLonLat(ol.proj.transform(coordinate, 'EPSG:3857', 'EPSG:4326'));
    	
    	//클릭시 위치 확대
    	map.getView().setZoom(10);
    	map.getView().setCenter(pos);
    	
    	$(element).popover('destroy');
    	
    	//팝업의 위치는 coordinate 변수에 담긴 위치
    	popup.setPosition(coordinate);
    	
    	//팝업창 객체 초기화
    	$(element).popover({
    		'placement': 'top',
    		'animation': false,
    		'html': true,
    		'content': '<p>너가 클릭한 곳이다!!</p><code>' + pos + '</code>'
    	});
    	
    	//객체 보여주기
    	$(element).popover('show');
    });
    
	//해당화면 extent구하기
	console.log(map.getView().calculateExtent());     
      
    $.support.cors = true;
     
     $(function(){
        $.ajax({
           type: 'get',
           url: 'https://api.vworld.kr/req/data?key=4F7654DB-A655-3075-8842-B2EFEB440741&domain=http://localhost:8080&service=data&version=2.0&request=getfeature&format=json&size=1000&page=1&geometry=false&attribute=true&crs=EPSG:3857&geomfilter=BOX(13663271.680031825,3894007.9689600193,14817776.555251127,4688953.0631258525)&data=LT_C_ADSIDO_INFO',
           async: false,
           dataType: 'jsonp',
           success: function(data) {              
              var html = '<option>선택</option>';
              data.response.result.featureCollection.features.forEach(function(f){
                 var ctprvn_cd = f.properties.ctprvn_cd;
                 var ctp_kor_nm = f.properties.ctp_kor_nm;                 
                 html += '<option value=' + ctprvn_cd + '>' + ctp_kor_nm + '(' + ctprvn_cd + ')</option>';   
              })
              
                 $('#sido_code').html(html);              
           },
           error: function(xhr, stat, err) {}
        });
        
		//시도 코드로 검색
        $(document).on("change","#sido_code",function(){
           
           let thisVal = $(this).val();      

           var targetName = "ctprvn_cd";
           var targetCode = thisVal;
           callAjax("LT_C_ADSIDO_INFO", targetName, targetCode);           

           $.ajax({
              type: 'get',
              url: 'https://api.vworld.kr/req/data?key=4F7654DB-A655-3075-8842-B2EFEB440741&domain=http://localhost:8080&service=data&version=2.0&request=getfeature&format=json&size=1000&page=1&geometry=false&attribute=true&crs=EPSG:3857&data=LT_C_ADSIGG_INFO',
              data : {attrfilter : 'sig_cd:like:'+thisVal},
              async: false,
              dataType: 'jsonp',
              success: function(data) {
                 var html = '<option>선택</option>';
                 
                 data.response.result.featureCollection.features.forEach(function(f){
                    console.log(f.properties)
                    var sig_cd = f.properties.sig_cd;
                    var sig_kor_nm = f.properties.sig_kor_nm;
                    
                    html +='<option value=' + sig_cd + '>' + sig_kor_nm + '(' + sig_cd + ')</option>'
                    
                 })
                    $('#sigoon_code').html(html);

                 var bbox = data.response.result.featureCollection.bbox;
                 var layer = "LT_C_ADSIDO_INFO";              
              
                 var select = new ol.interaction.Select();
                 map.addInteraction(select);
                 
                 
              },
              error: function(xhr, stat, err) {}
           });
        });
        
		//시군구 코드로 검색
        $(document).on("change","#sigoon_code",function(){ 
           
           let thisVal = $(this).val();      
           var targetName = "sig_cd";
           var targetCode = thisVal;
           callAjax("LT_C_ADSIGG_INFO",targetName,targetCode);
           
           $.ajax({
              type: 'get',
              url: 'https://api.vworld.kr/req/data?key=4F7654DB-A655-3075-8842-B2EFEB440741&domain=http://localhost:8080&service=data&version=2.0&request=getfeature&format=json&size=1000&page=1&geometry=false&attribute=true&crs=EPSG:3857&data=LT_C_ADEMD_INFO',
              data : {attrfilter : 'emd_cd:like:'+thisVal},
              async: false,
              dataType: 'jsonp',
              success: function(data) {
                 let html = '<option>선택</option>';

                 data.response.result.featureCollection.features.forEach(function(f){
                    console.log(f.properties)
                    let emd_cd = f.properties.emd_cd;
                    let emd_kor_nm = f.properties.emd_kor_nm;
                    html += '<option value='+emd_cd+'>'+emd_kor_nm+'('+emd_cd+')</option>'
                    
                 })
                    $('#dong_code').html(html);   
              },
              error: function(xhr, stat, err) {}
           });

        });

        //읍면 코드로 검색
        $(document).on("change","#dong_code",function(){ 
           let thisVal = $(this).val();   
           var targetName = "emd_cd";
           var targetCode = thisVal;
           callAjax("LT_C_ADEMD_INFO",targetName,targetCode);
           console.log('emd_targetName: ' + targetName);
           console.log('emd_targetCode: ' + targetCode);
           
           $.ajax({
              type: 'get',
              url: 'https://api.vworld.kr/req/data?key=4F7654DB-A655-3075-8842-B2EFEB440741&domain=http://localhost:8080&service=data&version=2.0&request=getfeature&format=json&size=1000&page=1&geometry=false&attribute=true&crs=EPSG:3857&data=LT_C_ADRI_INFO',
              data : {attrfilter : 'li_cd:like:'+thisVal},
              async: false,
              dataType: 'jsonp',
              success: function(data) {
                 let html = '<option>선택</option>';

                 data.response.result.featureCollection.features.forEach(function(f){
                    console.log(f.properties)
                    let li_cd = f.properties.li_cd;
                    let li_kor_nm = f.properties.li_kor_nm;
                    html +='<option value='+li_cd+'>'+li_kor_nm+'('+li_cd+')</option>'
                    
                 })
                    $('#lee_code').html(html);
              },
              error: function(xhr, stat, err) {}
           });

        });
        
        //리 코드로 검색
        $(document).on("change","#lee_code",function(){ 
            let thisVal = $(this).val();   
            var targetName = "li_cd";
            var targetCode = thisVal;
            callAjax("LT_C_ADRI_INFO",targetName,targetCode);          
         });
        
     })
	
    //centerExtent 값 구하기
	function getCenterOfExtent(Extent){
		var X = Extent[0] + (Extent[2] - Extent[0]) / 2;
		var Y = Extent[1] + (Extent[3] - Extent[1]) / 2;
		return [X, Y];
	}

	//공간정보를 올리기 위한 폴리곤 조회
	var callAjax = function(data,targetName,targetCode){
	 
	$.ajax({
		type: 'get',
		url: 'https://api.vworld.kr/req/data?key=4F7654DB-A655-3075-8842-B2EFEB440741&domain=http://localhost:8080&service=data&version=2.0&request=getfeature&format=json&size=1000&page=1&geometry=true&attribute=true&crs=EPSG:3857&data='
			+ data +'&attrfilter=' + targetName + ':like:' + targetCode,
		async: false,
		dataType: 'jsonp',
		success: function(data) {
			let vectorSource = new ol.source.Vector({features: (new ol.format.GeoJSON()).readFeatures(data.response.result.featureCollection)})
		
			//ol.format.GeoJson()).readFeatures Openlayers에서 제공하는 파서(해석)기능 제공
		
			map.getLayers().forEach(function(layer){
				if(layer.get("name")=="search_result"){
					map.removeLayer(layer);//기존결과 삭제
				}
			})
			let  vector_layer = new ol.layer.Vector({
				source: vectorSource,
				style: styleFunction
			})
		
			vector_layer.set("name","search_result");
			map.addLayer(vector_layer); // 지도 레이어에 데이터 API 호출결과 추가
		
		
			//선택된 지역의 extent[0,1,2,3]
			var vectorExtent = vectorSource.getExtent();
			//선택된 지역의 centerExtent
			var centerCoordinate = getCenterOfExtent(vectorExtent);                 
		             
			//extent에 맞게 화면이동, 20220629, dhin
			map.getView().fit(vectorExtent,{
			duration: 800
			});
		},
		error: function(xhr, stat, err) {}
		});
	}

   /* 폴리곤의 스타일 설정 */
  function styleFunction(feature) {

  return [
     new ol.style.Style({
        fill: new ol.style.Fill({ // 광역 시군 읍면에 따른 색상 변경
        //color: feature.get('ctp_kor_nm') == null ? feature.get('sig_kor_nm')==null? 'rgba(255,0,0,0.2)' : 'rgba(0,0,255,0.2)': 'rgba(0,255,0,0.2)'
   		color: feature.get('ctp_kor_nm') == null ? feature.get('sig_kor_nm')==null? feature.get('emd_kor_nm') == null ? 'rgba(255,0,0,0.2)' : 'rgba(0,0,255,0.2)': 'rgba(0,255,0,0.2)' : 'rgba(42,26,56,0.2)'
        }),
        stroke: new ol.style.Stroke({
        color: '#3399CC',
        width: 1.25
        }),
        
        //text레이블
/*         text: new ol.style.Text({
           offsetX:0.5, //위치설정
           offsetY:20,   //위치설정
           font: '20px Calibri,sans-serif',
           fill: new ol.style.Fill({ color: '#000' }),
           stroke: new ol.style.Stroke({
              color: '#fff', width: 3
           }),
           text: feature.get('ctp_kor_nm') == null ? feature.get('sig_kor_nm')==null? feature.get('emd_kor_nm') : feature.get('sig_kor_nm'): feature.get('ctp_kor_nm')
        }), */
        
        image: new ol.style.Icon(({
           anchor: [0.5, 10],
           anchorXUnits: 'fraction',
           anchorYUnits: 'pixels',
           src: 'http://map.vworld.kr/images/ol3/marker_blue.png'
        }))
     })
  ];
  }
    </script>
  </body>
</html>