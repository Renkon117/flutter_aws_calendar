# flutter_aws_calendar

ソースコード

# amplifyconfiguration.dartの生成
amplify configureを事項した際にamplifyconfiguration.dartファイルが生成されますので、各環境で作成してください。

# レクチャー動画の補足（2024年4月16日現在）

## 開発環境　Flutter 3.13.6

### section3のlecture1 4分45秒
    amplifyセットアップのドキュメントURL 
        https://docs.amplify.aws/flutter/start/project-setup/prerequisites/


	amplifyのバージョンはnpm install -g @aws-amplify/cliでインストール

	Android:
		app/src/build.gradle内で
            compileSdkVersion flutter.compileSdkVersionを34に変更
            minSdkVersion 21を21ではなく23に変更
		
	iOS:
		ios platform :13に変更する


section3のlecture2
GraphSQLのURL
https://docs.amplify.aws/flutter/build-a-backend/graphqlapi/


section3の24
fetchDataのURL
https://docs.amplify.aws/flutter/build-a-backend/graphqlapi/query-data/

section3の25
create, update, deleteのURL
https://docs.amplify.aws/flutter/build-a-backend/graphqlapi/mutate-data/



