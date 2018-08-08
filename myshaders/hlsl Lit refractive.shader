// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/hlsl Lit refractive" {
	Properties {
		_Color ("Texture Tint", Color) = (1,1,1,1)
		_MainTex ("Texture tint", 2D) = "white" {}

		_Normal ("Normal map", 2D) = "white" {}
	  	normalPo("Normal Power",Range(0,1))= 0
	  	_ColorSpec ("Specular Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_ColorRef ("Refraction Tint", Color) = (1,1,1,1)
	  	_IOR("IOR",Range(1.0,-1.0)) = 0

	  	roughness("LOD",Range(0,5)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular vertex:vert exclude_path:deferred exclude_path:prepass noshadow nolightmap interpolateview

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _Normal;
		float roughness;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _ColorSpec;
		fixed4 _ColorRef;

			float _IOR;
 		 	float normalPo;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Normal;
			//float4 vertex;
			float3 view;
			float3 norm;
		};


			float3 blendNormals(float3 n1, float3 n2){
				 return normalize(float3(n1.rg + n2.rg, n1.b * n2.b));
			}

			/*struct appdata{
			float4 vertex : POSITION;
			float2 tex : TEXCOORD1;
			float3 normal : NORMAL;
			};*/


		void vert (inout appdata_full v, out Input o) {
          UNITY_INITIALIZE_OUTPUT(Input,o);

          float4 vertex = UnityObjectToClipPos(v.vertex);

			//UNITY_TRANSFER_FOG(o,o.vertex);

			float4x4 modelMatrix = unity_ObjectToWorld;
	    	float4x4 modelMatrixInverse = unity_WorldToObject; 

	        o.view = mul(modelMatrix, v.vertex).xyz - _WorldSpaceCameraPos;
			//view = WorldSpaceViewDir(v.vertex);
	        o.norm = normalize( mul(float4(v.normal, 0.0), modelMatrixInverse).xyz);
	        //vertex = UnityObjectToClipPos(v.vertex);

	        //float3 normalTex = lerp(UnpackNormal(tex2Dlod(_MainTex, float4(v.texcoord1.xy,0,1))),float3(0,0,1),1-normalPo);

        	//normalDir = blendNormals(normalDir,normalTex);

            //o.refracted = refract(normalize(viewDirr), normalize(normalDir), _IOR);
            //o.refracted = tex2Dlod(_MainTex, float4(v.texcoord1.xy,0,0));
	        
           
      	}

		


		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling

	

		void surf (Input i, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			fixed4 textureTint = tex2D (_MainTex, i.uv_MainTex) * _Color ;
			//o.Albedo = c.rgb;
        	//float4x4 modelMatrixInverse = unity_WorldToObject; 

			

        	float3 normalTex = lerp(UnpackNormal(tex2D(_Normal, i.uv_Normal)),float3(0,0,1),1-normalPo);

        	i.norm = blendNormals(i.norm,normalTex);
            //float3 refractedDir = refract(normalize(i.refracted), normalize(normalTex), _IOR);

            float3 refracted = refract(normalize(i.view), normalize(i.norm), _IOR);

            float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,refracted, roughness );


            o.Specular = _ColorSpec;


            o.Normal = normalTex ;
            envSample *= _ColorRef;
			o.Albedo = float4(envSample.rgb * lerp(textureTint.rgb,float3(1,1,1),1-textureTint.a),1);
			//o.Albedo = float4(i.refracted,1);
			o.Smoothness = _Glossiness;
			o.Alpha = textureTint.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
