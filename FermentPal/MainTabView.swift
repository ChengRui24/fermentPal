//
//  MainTabView.swift
//  FermentPal
//
//  主标签视图 - 集成发酵罐列表和家谱视图
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 发酵罐列表
            ContentView(selectedTab: $selectedTab)
                .tabItem {
                    Label("发酵罐", systemImage: "list.bullet")
                }
                .tag(0)
            
            // 家谱视图
            GenealogyView()
                .tabItem {
                    Label("家谱", systemImage: "tree")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}

