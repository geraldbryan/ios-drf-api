import SwiftUI

struct ContentView: View {
    @State private var resultArray: NSArray?
    @State private var errorMessage: String?
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var login: Bool = false
    
    struct TwitterAccount: Codable, Identifiable {
            let id = UUID()
            let name: String
            let screenName: String
            let description: String
            let followersCount: Int
            let friendsCount: Int
            let statusesCount: Int

            private enum CodingKeys: String, CodingKey {
                case name
                case screenName = "screen_name"
                case description
                case followersCount = "followers_count"
                case friendsCount = "friends_count"
                case statusesCount = "statuses_count"
            }
        }

        var body: some View {
            VStack {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                    Button(action: closedButtonTapped) {
                        Text("Retry")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if let resultArray = resultArray {
                    List(getTwitterAccounts()) { account in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(account.name)
                                        .font(.headline)
                                    Text("@\(account.screenName)")
                                        .foregroundColor(.secondary)
                                    Text(account.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Text("Followers: \(account.followersCount)")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("Friends: \(account.friendsCount)")
                                            .foregroundColor(.green)
                                        Spacer()
                                        Text("Statuses: \(account.statusesCount)")
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                    Button(action: closedButtonTapped) {
                        Text("Closed")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }.padding(.horizontal)
                } else {
                    VStack(spacing: 20) {
                        Text("DRF API FETCHING")
                            .bold()
                            .foregroundColor(.blue)
                            .font(.largeTitle)
                            .padding(EdgeInsets(top: 0, leading: 50, bottom: 40, trailing: 50))
                            .multilineTextAlignment(.center)
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: submitButtonTapped) {
                            Text("Submit")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }.padding(.horizontal)
                        if login==true {
                            Text("Trying to connect to the DRF API ...")
                        }
                    }
                }
            }
        }
    
    func submitButtonTapped() {
        login = true
        authenticateUser(uname: username, pass: password)
    }
    
    func closedButtonTapped() {
        login = false
        errorMessage = nil
        resultArray = nil
        username = ""
        password = ""
    }
    
    // Decode NSArray object function
    func getTwitterAccounts() -> [TwitterAccount] {
        do {
            // Serialize NSarray data to json data
            let jsonData = try JSONSerialization.data(withJSONObject: resultArray, options: [])
            
            // Decode json data
            let decoder = JSONDecoder()
            return try decoder.decode([TwitterAccount].self, from: jsonData)
        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
    
    // Get the data from api
    func authenticateUser(uname: String, pass: String) {
        
        let authData = ["username": uname, "password": pass]
        
        // Get bearer token
        guard let authDataJson = try? JSONSerialization.data(withJSONObject: authData) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to serialize authentication data"
            }
            print("abc")
            return
        }

        let authUrlString = "https://bankindonesia-backend.herokuapp.com/api/token/"
        guard let authUrl = URL(string: authUrlString) else {
            DispatchQueue.main.async {
                errorMessage = "Invalid authentication URL"
            }
            print("abcd")
            return
        }

        var authRequest = URLRequest(url: authUrl)
        authRequest.httpMethod = "POST"
        authRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        authRequest.httpBody = authDataJson

        URLSession.shared.dataTask(with: authRequest) { data, response, error in
            if let error = error {
                
                DispatchQueue.main.async {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                print("abcdef")
                return
            }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let token = json["access"] as? String {
                
                // Fetch the API
                let apiPath = "https://bankindonesia-backend.herokuapp.com/api/twitter-profiles/"

                guard let apiUrl = URL(string: apiPath) else {
                    DispatchQueue.main.async {
                        errorMessage = "Invalid API URL"
                    }
                    return
                }

                var request = URLRequest(url: apiUrl)
                request.httpMethod = "GET"
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                                    DispatchQueue.main.async {
                                        errorMessage = error.localizedDescription
                                    }
                                    return
                                }

                    if let httpResponse = response as? HTTPURLResponse {
                        let statusCode = httpResponse.statusCode
                        print("Status Code: \(statusCode)")
                    }
                    
                    // Take the data
                    guard let data = data else {
                                    DispatchQueue.main.async {
                                        errorMessage = "No data received"
                                    }
                                    return
                                }

                                do {
                                    let json = try JSONSerialization.jsonObject(with: data, options: [])

                                    if let dictionary = json as? [String: Any],
                                                       let result = dictionary["results"] as? NSArray {
                                                        DispatchQueue.main.async {
                                                            self.resultArray = result
                                                        }

                                                    } else {
                                                        DispatchQueue.main.async {
                                                                                errorMessage = "Failed to parse JSON or extract result array"
                                                                            }
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                                        errorMessage = error.localizedDescription
                                                    }
                                }
                }.resume()
            } else {
                DispatchQueue.main.async {
                                    errorMessage = "Invalid Credentials, failed to parse JSON response"
                                }
                print("Error: Failed to parse JSON response")
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
