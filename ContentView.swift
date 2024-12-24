import SwiftUI
import SDWebImageSwiftUI

struct PetView: View {
    @State private var currentGif = "布偶熊站立透明.gif" // 默认播放普通动画
    @State private var isReacting = false       // 标记是否处于点击状态
    let normalGif = "布偶熊站立透明.gif"                // 普通动画
    let clickGifs = ["布偶熊动作透明1.gif",
                     "布偶熊动作透明2.gif",
                     "布偶熊动作透明3.gif",
                     "布偶熊动作透明4.gif",]  // 点击时的多个反应动画
    // 每个 GIF 动画对应的播放时长（秒）
    let gifDurations: [TimeInterval] = [3.5, 4.95, 4.95, 4.5]
    // 用户输入的文本
        @State private var userInput = ""
        
        // AI 的回复
        @State private var aiResponse = ""
        
        @State private var isThinking = false  // 思考状态变量
        
    // API 调用函数
    func sendRequest(userInput: String) {
        isThinking = true
        aiResponse = "让我想想..."
        
        let apiUrl = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        let apiKey = ""//添加智谱清言的API
        
        // 创建请求内容
        let requestBody: [String: Any] = [
            "model": "glm-4",
            "messages": [
                ["role": "system", "content":"你的名字叫布偶熊·觅语，用可爱的风格回答问题，在回答问题前都要说：指挥官，你好。"],
                ["role": "user", "content": userInput]
            ],
            "top_p": 0.7,
            "temperature": 0.9
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            DispatchQueue.main.async {
                self.aiResponse = "错误：无法创建请求数据"
                self.isThinking = false
            }
            return
        }
        
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isThinking = false
                
                if let error = error {
                    self.aiResponse = "网络错误：\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.aiResponse = "错误：未收到数据"
                    return
                }
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.aiResponse = content
                    } else {
                        self.aiResponse = "错误：无法解析响应数据"
                    }
                } catch {
                    self.aiResponse = "JSON解析错误：\(error.localizedDescription)"
                }
            }
        }.resume()
        }

    var body: some View {
        VStack {
                // 透明输入框
                TextField("我会帮助指挥官解决问题...", text: $userInput)
                    .padding(10)
                    .background(Color.clear)//透明背景
                    .cornerRadius(8)
                    .textFieldStyle(PlainTextFieldStyle()) //去除默认边框和蓝色框选
                    .padding([.top, .leading, .trailing])
                    .onSubmit {
                        //当按下回车键时触发提交操作
                        sendRequest(userInput: userInput)
                        userInput = "" // 清空输入框
                    }

                // 显示 AI 回复的区域，支持滚动
                ScrollView {
                    Text(aiResponse)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(isThinking ? 0.6 : 1)  // 思考时文字显示为半透明
                }
                .frame(maxWidth: .infinity, maxHeight: 80) // 限制输出框的高度
                .background(Color.white.opacity(0.2))//透明背景
                .cornerRadius(8)
                .padding([.leading, .trailing])
            }
        ZStack {
            Color.clear // 背景透明
            AnimatedImage(name: currentGif) // 根据状态显示对应 GIF
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .onTapGesture {
                    handleTap() // 点击事件
                }
        }

        .frame(width: 200, height: 200)
    }

    private func handleTap() {
        guard !isReacting else { return } // 防止点击多次重复触发
        isReacting = true

        // 创建一个队列依次播放多个 GIF 动画
        playNextGif(index: 0)
    }
    
    private func playNextGif(index: Int) {
        guard index < clickGifs.count else {
            // 所有动画播放完毕后恢复普通动画
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                currentGif = normalGif
                isReacting = false
            }
            return
        }

        // 播放当前 GIF
        currentGif = clickGifs[index]
        
        // 获取当前 GIF 的播放时长
        let gifDuration = gifDurations[index]

        DispatchQueue.main.asyncAfter(deadline: .now() + gifDuration) {
            // 播放下一个 GIF
            playNextGif(index: index + 1)
        }
    }
}



struct ContentView: View {
    var body: some View {
        PetView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
